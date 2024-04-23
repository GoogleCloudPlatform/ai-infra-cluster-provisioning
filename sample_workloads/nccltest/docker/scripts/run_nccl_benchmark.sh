#!/bin/bash

set -u
set -o pipefail

# Job parameters.
: "${JOB_TIMESTAMP:?Must set JOB_TIMESTAMP}"
: "${JOB_NAME:?Must set JOB_NAME}"
: "${RUN_USER:?Must set RUN_USER}"
: "${VERSION_VECTOR:?Must set VERSION_VECTOR}"
: "${DESCRIPTION:?Must set DESCRIPTION}"
: "${IS_LKG:?Must set IS_LKG}"
: "${NNODES:?Must set NNODES}"
: "${GCS_ROOT_DIR:?Must set GCS_ROOT_DIR}"
: "${BM_LOG_DIR:?Must set BM_LOG_DIR}"
: "${BM_LOG_GCS_URL:?Must set BM_LOG_GCS_URL}"

# Benchmark parameters.
: "${BENCHMARK:?Must set BENCHMARK}"
: "${MASK:?Must set MASK}"
: "${MSG_SIZES_CSV:?Must set MSG_SIZES_CSV}"
: "${GPUS_PER_NODE:?Must set GPUS_PER_NODE}"
: "${N_COMMS:?Must set N_COMMS}"
: "${WARMUP_ITERS:?Must set WARMUP_ITERS}"
: "${RUN_ITERS:?Must set RUN_ITERS}"
: "${N_RUNS:?Must set N_RUNS}"
: "${DATA_CHECK:?Must set DATA_CHECK}"

# Unreserved cores for taskset call. This is a CSV of ranges for cores unused.
: "${UNRESERVED_CORES:?Must set UNRESERVED_CORES}"

# Modularized telemetry.
: "${NIC_TELEMETRY:?Must set NIC_TELEMETRY}"
: "${TCP_TELEMETRY:?Must set TCP_TELEMETRY}"
: "${CPU_TELEMETRY:?Must set CPU_TELEMETRY}"
: "${GPU_TELEMETRY:?Must set GPU_TELEMETRY}"
: "${KERNEL_TELEMETRY:?Must set KERNEL_TELEMETRY}"

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
echo
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
    -x "DATA_CHECK=${DATA_CHECK}" \
    -x "UNRESERVED_CORES=${UNRESERVED_CORES}" \
    -x "NIC_TELEMETRY=${NIC_TELEMETRY}" \
    -x "TCP_TELEMETRY=${TCP_TELEMETRY}" \
    -x "CPU_TELEMETRY=${CPU_TELEMETRY}" \
    -x "GPU_TELEMETRY=${GPU_TELEMETRY}" \
    -x "KERNEL_TELEMETRY=${KERNEL_TELEMETRY}" \
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

# Post processing.
LKG_PKL_PATH="${GCS_ROOT_DIR}/lkg_results.pkl"

# Obtain a mutex guarding the LKG results.
MUTEX_PATH="${GCS_ROOT_DIR}/lkg_mutex"

# Make sure the mutex is cleaned up if the container receives a SIGINT/SIGTERM
# to prevent deadlocks in subsequent runs.
sighdl () {
  echo "caught SIGINT/SIGTERM, cleaning up mutex..."
  rm -f "$MUTEX_PATH"
}
trap sighdl SIGINT SIGTERM

# Wait till we can grab the mutex.
while [[ -f "$MUTEX_PATH" ]]; do
  MUTEX_HELD_SINCE=$( date -r "$MUTEX_PATH" +%s )
  TIME_NOW=$( date +%s )
  MUTEX_HELD_TIME=$(( TIME_NOW - MUTEX_HELD_SINCE ))

  # Forcibly release the mutex after someone is holding the mutex for 5 minutes.
  # This probably means a previous execution hung or was killed during post-
  # processing with a SIGKILL, leaking the mutex.
  if [[ "$MUTEX_HELD_TIME" -gt 300 ]]; then
    echo "Forcibly releasing mutex held over 5 minutes..."
    echo "This probably indicates a leaked mutex from a prior run."
    rm -f "$MUTEX_PATH"
  fi

  sleep 1
done

echo "Grabbing mutex for post-processing..."
touch "$MUTEX_PATH"

python3 result_parser.py \
  --job_timestamp "$JOB_TIMESTAMP" --job_name "$JOB_NAME" \
  --run_user "$RUN_USER" --version_vector "$VERSION_VECTOR" \
  --description "$DESCRIPTION" --is_lkg "$IS_LKG" \
  --lkg_pkl_path "$LKG_PKL_PATH" --bm_log_dir "$BM_LOG_DIR" \
  --bm_log_gcs_url "$BM_LOG_GCS_URL" \
  --nnodes "$NNODES" --gpus_per_node "$GPUS_PER_NODE" \
  --benchmark "$BENCHMARK" --mask "$MASK" \
  --n_comms "$N_COMMS" --warmup_iters "$WARMUP_ITERS" \
  --run_iters "$RUN_ITERS" --n_runs "$N_RUNS"

echo "Releasing mutex after post-processing..."
rm -f "$MUTEX_PATH"
