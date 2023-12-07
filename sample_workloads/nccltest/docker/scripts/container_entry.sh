#!/bin/bash

# Container entry script. Runs NCCL-level benchmarks and report results.

set -u

# Job parameters.
: "${JOB_TIMESTAMP:?Must set JOB_TIMESTAMP}"
: "${JOB_NAME:?Must set JOB_NAME}"
: "${MASTER_ADDR:?Must set MASTER_ADDR}"
: "${NNODES:?Must set NNODES}"
: "${NODE_RANK:?Must set NODE_RANK}"

# GCS bucket to be used.
: "${GCS_BUCKET:?Must set GCS_BUCKET}"

# Benchmark parameters.
: "${BENCHMARKS_CSV:?Must set BENCHMARKS_CSV}"
: "${MASKS_CSV:?Must set MASKS_CSV}"
: "${MSG_SIZE_BEGIN:?Must set MSG_SIZE_BEGIN}"
: "${MSG_SIZE_END:?Must set MSG_SIZE_END}"
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

# If input is malformed, error straight away.
IFS=',' read -r -a BENCHMARKS <<< "$BENCHMARKS_CSV"
IFS=',' read -r -a MASKS <<< "$MASKS_CSV"

if [[ "${#BENCHMARKS[@]}" -ne "${#MASKS[@]}" ]]; then
  echo "Mismatching length of BENCHMARKS_CSV and MASKS_CSV, aborting..."
  exit 1
fi

for BENCHMARK in ${BENCHMARKS[@]}; do
  if [[ "$BENCHMARK" != "all_gather_perf"     && "$BENCHMARK" != "all_reduce_perf" && \
        "$BENCHMARK" != "reduce_scatter_perf" && "$BENCHMARK" != "broadcast_perf" && \
        "$BENCHMARK" != "reduce_perf"         && "$BENCHMARK" != "sendrecv_perf" && \
        "$BENCHMARK" != "scatter_perf"        && "$BENCHMARK" != "gather_perf" && \
        "$BENCHMARK" != "alltoall_perf"       && "$BENCHMARK" != "hypercube_perf" ]]; then
    echo "${BENCHMARK} is not a legal benchmark, aborting..."
    exit 2
  fi
done

for MASK in ${MASKS[@]}; do
  if [[ "$MASK" -ge "$GPUS_PER_NODE" ]]; then
    echo "Mask ${MASK} is greater than ${GPUS_PER_NODE}, this might create" \
         "an asymmetric traffic pattern across VMs, aborting..."
    exit 3
  fi
done

# Create shared directory for GCE compatibility.
mkdir -p /usr/share/nccl_benchmarks

# Wait for master node to be ready.
MASTER_READY=""
while [[ -z "$MASTER_READY" ]]; do
  echo "Waiting for master..."
  MASTER_READY=$( getent hosts ${MASTER_ADDR} )
  echo $MASTER_READY
  sleep 5
done

# IRQ tunings.
/scripts/tune_net.sh

# Start SSH service on hosts and send address of self to master node.
mkdir -p /run/mpi_bootstrap
service ssh start

RANK_FILENAME="rank${NODE_RANK}.txt"
hostname > "$RANK_FILENAME"
while true; do
  scp -o StrictHostKeyChecking=no -P 222 \
    "$RANK_FILENAME" "${MASTER_ADDR}:/run/mpi_bootstrap/"

  EXIT_STATUS=$?
  if [[ "$EXIT_STATUS" -eq 0 ]]; then
    break
  fi
  sleep 1
done

# Mount GCS.
echo "Mounting GCS..."
GCS_ROOT_DIR=/workspace/logs
mkdir -p "$GCS_ROOT_DIR"
gcsfuse --implicit-dirs "$GCS_BUCKET" "$GCS_ROOT_DIR"

JOB_LOG_DIR_NAME="${JOB_TIMESTAMP}_${JOB_NAME}_nnodes_${NNODES}_gpus_${GPUS_PER_NODE}"
JOB_LOG_DIR="${GCS_ROOT_DIR}/${JOB_LOG_DIR_NAME}"
echo "GCS mount complete; results at ${GCS_BUCKET}/${JOB_LOG_DIR_NAME}"

if [[ "$NODE_RANK" -eq 0 ]]; then
  # Once host information has arrived, initialize SSH, generate hostfile, and
  # start the tests.
  echo "Waiting for host information to arrive..."
  NRANKS_READY=0
  while [[ "$NRANKS_READY" -lt "$NNODES" ]]; do
    NRANKS_READY=$( ls /run/mpi_bootstrap/rank*.txt | wc -l )
    sleep 1
  done

  for (( i = 0; i < NNODES; ++i )); do
    cat "/run/mpi_bootstrap/rank${i}.txt" >> /run/mpi_bootstrap/hosts.txt
  done

  cat /run/mpi_bootstrap/hosts.txt | xargs /scripts/init_ssh.sh
  pushd /scripts
  cat /run/mpi_bootstrap/hosts.txt | xargs /scripts/gen_hostfiles.sh
  popd

  # Run workload and process results.
  for i in "${!BENCHMARKS[@]}"; do
    BENCHMARK=${BENCHMARKS[i]}
    MASK=${MASKS[i]}
    echo "Running benchmark ${BENCHMARK} with mask ${MASK}..."

    BM_LOG_DIR="${JOB_LOG_DIR}/bm_${BENCHMARK}_mask_${MASK}"
    mkdir -p "$BM_LOG_DIR"

    NNODES="$NNODES" \
    BM_LOG_DIR="$BM_LOG_DIR" \
    BENCHMARK="$BENCHMARK" \
    MASK="$MASK" \
    MSG_SIZE_BEGIN="$MSG_SIZE_BEGIN" \
    MSG_SIZE_END="$MSG_SIZE_END" \
    GPUS_PER_NODE="$GPUS_PER_NODE" \
    N_COMMS="$N_COMMS" \
    WARMUP_ITERS="$WARMUP_ITERS" \
    RUN_ITERS="$RUN_ITERS" \
    N_RUNS="$N_RUNS" \
    UNRESERVED_CORES="$UNRESERVED_CORES" \
    GPU_TELEMETRY="$GPU_TELEMETRY" \
      "${SCRIPT_DIR}/run_nccl_benchmark.sh"
  done

  # Tell each node the MPI workload has terminated.
  mpirun --mca btl tcp,self --mca btl_tcp_if_include eth0 \
    --mca routed direct --allow-run-as-root \
    -np "$NNODES" --hostfile /scripts/hostfiles${NNODES}/hostfile1 \
    touch /usr/share/nccl_benchmarks/workload_terminated
else
  while [[ ! -e /usr/share/nccl_benchmarks/workload_terminated ]]; do
    sleep 10
  done
fi