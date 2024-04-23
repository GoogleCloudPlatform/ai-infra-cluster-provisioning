#!/bin/bash

# Container entry script. Runs NCCL-level benchmarks and report results.

set -u

# Job parameters.
: "${JOB_TIMESTAMP:?Must set JOB_TIMESTAMP}"
: "${JOB_NAME:?Must set JOB_NAME}"
: "${RUN_USER:?Must set RUN_USER}"
: "${VERSION_VECTOR:?Must set VERSION_VECTOR}"
: "${DESCRIPTION:?Must set DESCRIPTION}"
: "${IS_LKG:?Must set IS_LKG}"
: "${MASTER_ADDR:?Must set MASTER_ADDR}"
: "${NNODES:?Must set NNODES}"
: "${NODE_RANK:?Must set NODE_RANK}"

# GCS bucket to be used.
: "${GCS_BUCKET:?Must set GCS_BUCKET}"

# Benchmark parameters.
: "${BENCHMARKS_CSV:?Must set BENCHMARKS_CSV}"
: "${MASKS_CSV:?Must set MASKS_CSV}"
: "${MSG_SIZES_CSV:?Must set MSG_SIZES_CSV}"
: "${GPUS_PER_NODE:?Must set GPUS_PER_NODE}"
: "${N_COMMS:?Must set N_COMMS}"
: "${WARMUP_ITERS:?Must set WARMUP_ITERS}"
: "${RUN_ITERS:?Must set RUN_ITERS}"
: "${N_RUNS:?Must set N_RUNS}"
: "${DATA_CHECK:?Must set DATA_CHECK}"

# Tuning scripts.
: "${TUNING_SCRIPT:=none}"

# Unreserved cores for taskset call. This is a CSV of ranges for cores unused.
: "${UNRESERVED_CORES:?Must set UNRESERVED_CORES}"

# Modularized telemetry.
: "${TELEMETRY:?Must set TELEMETRY}"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# If input is malformed, error straight away.
IFS=',' read -r -a BENCHMARKS <<< "$BENCHMARKS_CSV"
IFS=',' read -r -a MASKS <<< "$MASKS_CSV"

if [[ "${#BENCHMARKS[@]}" -ne "${#MASKS[@]}" ]]; then
  echo "Mismatching length of BENCHMARKS_CSV and MASKS_CSV, aborting..."
  exit 1
fi

for BENCHMARK in ${BENCHMARKS[@]}; do
  if [[ "$BENCHMARK" != "AllGather"     && "$BENCHMARK" != "AllReduce" && \
        "$BENCHMARK" != "ReduceScatter" && "$BENCHMARK" != "Broadcast" && \
        "$BENCHMARK" != "Reduce"        && "$BENCHMARK" != "SendRecv" && \
        "$BENCHMARK" != "Scatter"       && "$BENCHMARK" != "Gather" && \
        "$BENCHMARK" != "AlltoAll"      && "$BENCHMARK" != "HyperCube" ]]; then
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
  MASTER_READY=$( getent hosts ${MASTER_ADDR} )
  sleep 1
done

# Run tuning scripts.
if [[ "$TUNING_SCRIPT" != "none" ]]; then
  bash "$TUNING_SCRIPT"
fi

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
JOB_LOG_GCS_URL="https://pantheon.corp.google.com/storage/browser/${GCS_BUCKET}/${JOB_LOG_DIR_NAME}"
echo "GCS mount complete; results at ${JOB_LOG_GCS_URL}..."

LKG_PKL_PATH="${GCS_ROOT_DIR}/lkg_results.pkl"

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

  # Process potentially human-readable message sizes to bytes.
  IFS=',' read -r -a MSG_SIZES <<< "$MSG_SIZES_CSV"
  for i in "${!MSG_SIZES[@]}"; do
    MSG_SIZES[i]=$( numfmt --from=iec "${MSG_SIZES[i]}" )
  done
  printf -v MSG_SIZES_CSV '%s,' "${MSG_SIZES[@]}"
  # Truncate last comma.
  MSG_SIZES_CSV="${MSG_SIZES_CSV::-1}"

  # Process telemetry modules enabled.
  NIC_TELEMETRY="false"
  TCP_TELEMETRY="false"
  CPU_TELEMETRY="false"
  GPU_TELEMETRY="false"
  KERNEL_TELEMETRY="false"
  # Lower case input. This should not be case sensitive.
  TELEMETRY=${TELEMETRY,,}
  if [[ "$TELEMETRY" =~ ^(none|no|false|0)$ ]]; then
    echo "No telemetry modules enabled."
  elif [[ "$TELEMETRY" =~ ^(all|yes|true|1)$ ]]; then
    echo "All telemetry modules enabled."
    NIC_TELEMETRY="true"
    TCP_TELEMETRY="true"
    CPU_TELEMETRY="true"
    GPU_TELEMETRY="true"
    KERNEL_TELEMETRY="true"
  else
    IFS=',' read -r -a TELEMETRY_MODULES <<< "$TELEMETRY"
    for TELEMETRY_MODULE in "${TELEMETRY_MODULES[@]}"; do
      if [[ "$TELEMETRY_MODULE" == "nic" ]]; then
        NIC_TELEMETRY="true"
      elif [[ "$TELEMETRY_MODULE" == "tcp" ]]; then
        TCP_TELEMETRY="true"
      elif [[ "$TELEMETRY_MODULE" == "cpu" ]]; then
        CPU_TELEMETRY="true"
      elif [[ "$TELEMETRY_MODULE" == "gpu" ]]; then
        GPU_TELEMETRY="true"
      elif [[ "$TELEMETRY_MODULE" == "kernel" ]]; then
        KERNEL_TELEMETRY="true"
      else
        echo "Unknown telemetry module: ${TELEMETRY_MODULE}, skipping..."
      fi
    done
  fi

  # Run workload and process results.
  for i in "${!BENCHMARKS[@]}"; do
    BENCHMARK=${BENCHMARKS[i]}
    MASK=${MASKS[i]}
    echo "Running benchmark ${BENCHMARK} with mask ${MASK}..."

    BM_LOG_DIR_NAME="bm_${BENCHMARK}_mask_${MASK}"
    BM_LOG_DIR="${JOB_LOG_DIR}/${BM_LOG_DIR_NAME}"
    mkdir -p "$BM_LOG_DIR"
    BM_LOG_GCS_URL="${JOB_LOG_GCS_URL}/${BM_LOG_DIR_NAME}"
    echo "Results at ${BM_LOG_GCS_URL}"
    echo

    JOB_TIMESTAMP="$JOB_TIMESTAMP" \
    JOB_NAME="$JOB_NAME" \
    RUN_USER="$RUN_USER" \
    VERSION_VECTOR="$VERSION_VECTOR" \
    DESCRIPTION="$DESCRIPTION" \
    IS_LKG="$IS_LKG" \
    NNODES="$NNODES" \
    GCS_ROOT_DIR="$GCS_ROOT_DIR" \
    BM_LOG_DIR="$BM_LOG_DIR" \
    BM_LOG_GCS_URL="$BM_LOG_GCS_URL" \
    BENCHMARK="$BENCHMARK" \
    MASK="$MASK" \
    MSG_SIZES_CSV="$MSG_SIZES_CSV" \
    GPUS_PER_NODE="$GPUS_PER_NODE" \
    N_COMMS="$N_COMMS" \
    WARMUP_ITERS="$WARMUP_ITERS" \
    RUN_ITERS="$RUN_ITERS" \
    N_RUNS="$N_RUNS" \
    DATA_CHECK="$DATA_CHECK" \
    UNRESERVED_CORES="$UNRESERVED_CORES" \
    NIC_TELEMETRY="$NIC_TELEMETRY" \
    TCP_TELEMETRY="$TCP_TELEMETRY" \
    CPU_TELEMETRY="$CPU_TELEMETRY" \
    GPU_TELEMETRY="$GPU_TELEMETRY" \
    KERNEL_TELEMETRY="$KERNEL_TELEMETRY" \
      "${SCRIPT_DIR}/run_nccl_benchmark.sh"

    echo "Benchmark complete; results at ${BM_LOG_GCS_URL}"
    echo
  done

  echo "Job ${JOB_NAME} complete; results at ${JOB_LOG_GCS_URL}"

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
