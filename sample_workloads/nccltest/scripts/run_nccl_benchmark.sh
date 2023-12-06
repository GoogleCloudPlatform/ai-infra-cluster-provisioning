#!/bin/bash

set -u
set -o pipefail

# Job parameters.
: "${NNODES:?Must set NNODES}"
: "${BM_LOG_DIR:?Must set BM_LOG_DIR}"

# Benchmark parameters.
: "${BENCHMARK:?Must set BENCHMARK}"
: "${MASK:?Must set MASK}"
: "${MSG_SIZES_CSV:?Must set MSG_SIZES_CSV}"
: "${GPUS_PER_NODE:?Must set GPUS_PER_NODE}"
: "${N_COMMS:?Must set N_COMMS}"
: "${WARMUP_ITERS:?Must set WARMUP_ITERS}"
: "${RUN_ITERS:?Must set RUN_ITERS}"
: "${N_RUNS:?Must set N_RUNS}"

# Unreserved cores for taskset call. This is a CSV of ranges for cores unused
# by TCPX.
: "${UNRESERVED_CORES:?Must set UNRESERVED_CORES}"

# Telemetry.
: "${GPU_TELEMETRY:?Must set GPU_TELEMETRY}"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

IFS=',' read -r -a MSG_SIZES <<< "$MSG_SIZES_CSV"
NRANKS=$(( NNODES * GPUS_PER_NODE ))

# Compute number of NCCL communicators.
N_NCCL_COMMS=1
MASK_CPY="$MASK"
while [[ "$MASK_CPY" -gt 0 ]]; do
  : $(( N_NCCL_COMMS <<= (MASK_CPY & 1), MASK_CPY >>= 1 ))
done

# Generate input file content for all message sizes.
TOTAL_ITERS=$(( WARMUP_ITERS + RUN_ITERS ))
ENDL=$'\n'
# TODO: b/310239133 - Once this is fixed, need to change input file format to
# textprotos.
echo "Generating input file for benchmark..."
BENCHMARK_INPUT="COMM_GROUP_SPLIT_MASK ${MASK}${ENDL}"
for MSG_SIZE in "${MSG_SIZES[@]}"; do
  # First divide by size of float (4).
  COUNT=$(( MSG_SIZE / 4 ))
  # Then divide by number of ranks, if necessary.
  if [[ "$BENCHMARK" == "AllGather" || "$BENCHMARK" == "ReduceScatter" ]]; then
    COUNT=$(( COUNT / ( NRANKS / N_NCCL_COMMS ) ))
  fi

  # Add the benchmark parameters for this message size.
  #                 benchmark     count     dtype  reduce_op  root
  BENCHMARK_INPUT+="${BENCHMARK}  ${COUNT}  float  sum        0     "
  #                 comm_group  comm_restart  repeat
  BENCHMARK_INPUT+="0           0             ${TOTAL_ITERS}${ENDL}"
done

# Create input file for all nodes to be used by run_colls.
mpirun --mca btl tcp,self --mca btl_tcp_if_include eth0 \
  --mca routed direct --allow-run-as-root \
  -np "$NNODES" --hostfile "/scripts/hostfiles${NNODES}/hostfile1" \
  bash -c "echo \"$BENCHMARK_INPUT\" > ${SCRIPT_DIR}/benchmark_input"

# Generate CUDA_VISIBLE_DEVICES.
CUDA_VISIBLE_DEVICES=$( seq -s, 0 1 $(( GPUS_PER_NODE - 1 )) )

# Generate NCCL flags for application.
NCCL_FLAGS=$( env | egrep ^NCCL | awk '{ printf "-x %s ", $0; }' )

# Run actual NCCL benchmarks.
for (( i = 1; i <= N_RUNS; ++i )); do
  RUN_LOG_DIR="${BM_LOG_DIR}/per_run_results/run_${i}"
  mkdir -p "$RUN_LOG_DIR"
  LOGFILE_PATH="${RUN_LOG_DIR}/logs.txt"

  echo "benchmark: ${BENCHMARK}, mask: ${MASK}, run ${i}/${N_RUNS}"

  # Run benchmark, with a 3-hour timeout.
  mpirun --mca btl tcp,self --mca btl_tcp_if_include eth0 \
    --mca routed direct --allow-run-as-root -np "$NRANKS" \
    --hostfile "/scripts/hostfiles${NNODES}/hostfile${GPUS_PER_NODE}" \
    --timeout $(( 3 * 60 * 60 )) \
    -x LD_LIBRARY_PATH -x PATH \
    -x "CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES}" \
    $NCCL_FLAGS \
    -x "RUN_LOG_DIR=${RUN_LOG_DIR}" \
    -x "N_COMMS=${N_COMMS}" \
    -x "UNRESERVED_CORES=${UNRESERVED_CORES}" \
    -x "GPU_TELEMETRY=${GPU_TELEMETRY}" \
      "${SCRIPT_DIR}/mpi_entry.sh" 2>&1 | \
  tee "$LOGFILE_PATH"

  EXIT_STATUS=$?
  if [[ "$EXIT_STATUS" -ne 0 ]]; then
    echo "WARNING: got non-zero exit status ${EXIT_STATUS}"
  fi

  # Generate the CSVs for the run.
  CSV_PATH="${RUN_LOG_DIR}/results.csv"
  grep "float" "$LOGFILE_PATH" | \
    awk '{ printf "%s,%s,%s\n", $4, $9, $11 }' > "$CSV_PATH"
done