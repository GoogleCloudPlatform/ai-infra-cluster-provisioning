#!/bin/bash

# Job parameters.
: "${RUN_LOG_DIR:?Must set RUN_LOG_DIR}"

# Benchmark parameters.
: "${N_COMMS:?Must set N_COMMS}"
: "${DATA_CHECK:?Must set DATA_CHECK}"

# Unreserved cores for taskset call. This is a CSV of ranges for cores unused.
: "${UNRESERVED_CORES:?Must set UNRESERVED_CORES}"

# Modularized telemetry.
: "${NIC_TELEMETRY:?Must set NIC_TELEMETRY}"
: "${TCP_TELEMETRY:?Must set TCP_TELEMETRY}"
: "${CPU_TELEMETRY:?Must set CPU_TELEMETRY}"
: "${GPU_TELEMETRY:?Must set GPU_TELEMETRY}"
: "${KERNEL_TELEMETRY:?Must set KERNEL_TELEMETRY}"

# OpenMPI parameters.
: "${OMPI_COMM_WORLD_RANK:?Must set OMPI_COMM_WORLD_RANK}"
: "${OMPI_COMM_WORLD_LOCAL_SIZE:?Must set OMPI_COMM_WORLD_LOCAL_SIZE}"
: "${OMPI_COMM_WORLD_LOCAL_RANK:?Must set OMPI_COMM_WORLD_LOCAL_RANK}"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Compute node rank based on global rank and local world size.
# This is a workaround for us not being able to send this info directly in MPI.
NODE_RANK=$(( OMPI_COMM_WORLD_RANK / OMPI_COMM_WORLD_LOCAL_SIZE ))

TELEMETRY_DIR="${RUN_LOG_DIR}/telemetry/node${NODE_RANK}"
mkdir -p "$TELEMETRY_DIR"

# Get all physical network interfaces.
mapfile -t ALL_IFS \
  < <( find /sys/class/net -type l -not -lname '*virtual*' -printf '%f\n' )

# NIC telemetry (qdisc).
if [[ "$OMPI_COMM_WORLD_LOCAL_RANK" == "0" ]] && \
      "$NIC_TELEMETRY" == "true" ]]; then
  NIC_TELEMETRY_DIR="${TELEMETRY_DIR}/nic"
  mkdir -p "$NIC_TELEMETRY_DIR"

  # Queuing discipline statistics.
  while true; do
    TZ=America/Los_Angeles date; tc -s -d qdisc show; sleep 1
  done > "${NIC_TELEMETRY_DIR}/qdisc.txt" &
fi

# TCP telemetry (ss, nstat, tcpdump).
if [[ "$OMPI_COMM_WORLD_LOCAL_RANK" == "0" && \
      "$TCP_TELEMETRY" == "true" ]]; then
  TCP_TELEMETRY_DIR="${TELEMETRY_DIR}/tcp"
  mkdir -p "$TCP_TELEMETRY_DIR"

  # Socket statistics.
  while true; do
    TZ=America/Los_Angeles date; ss -tenmoi; sleep 1
  done > "${TCP_TELEMETRY_DIR}/ss.txt" &

  # Network statistics.
  nstat -n
  while true; do
    TZ=America/Los_Angeles date; nstat; sleep 1
  done > "${TCP_TELEMETRY_DIR}/nstat.txt" &

  # Capture TCP packets.
  TCPDUMP_DIR="${TCP_TELEMETRY_DIR}/tcpdump"
  mkdir -p "${TCPDUMP_DIR}"
  for IF in ${ALL_IFS[@]}; do
    tcpdump -w "${TCPDUMP_DIR}/${IF}.pcap" -n -s 116 -i "$IF" &
  done
fi

# CPU statistics (mpstat).
if [[ "$OMPI_COMM_WORLD_LOCAL_RANK" == "0" && \
      "$CPU_TELEMETRY" == "true" ]]; then
  CPU_TELEMETRY_DIR="${TELEMETRY_DIR}/cpu"
  mkdir -p "$CPU_TELEMETRY_DIR"

  # Processor statistics.
  mpstat -P ALL 1 > "${CPU_TELEMETRY_DIR}/mpstat.txt" &
fi

# GPU profiling.
NSYS_PREFIX=""
if [[ "$GPU_TELEMETRY" == "true" ]]; then
  GPU_TELEMETRY_DIR="${TELEMETRY_DIR}/gpu"
  mkdir -p "$GPU_TELEMETRY_DIR"
  GPU_TELEMETRY_OUTPUT="${GPU_TELEMETRY_DIR}/rank${OMPI_COMM_WORLD_LOCAL_RANK}"
  NSYS_PREFIX="nsys profile \
                  --wait primary -o ${GPU_TELEMETRY_OUTPUT} \
                  --force-overwrite true -t cuda,nvtx -s none --export sqlite"
  export NCCL_PROXY_NVTX_ENABLE=1
fi

# Set the user limit for number of open files allowed per process.
ulimit -n 1048576

# Dump NCCL info logs to GCS.
NCCL_LOGS_DIR="${TELEMETRY_DIR}/nccl"
mkdir -p "$NCCL_LOGS_DIR"
export NCCL_DEBUG=INFO
export NCCL_DEBUG_SUBSYS=INIT,NET,GRAPH,TUNING,ENV
export NCCL_DEBUG_FILE="${NCCL_LOGS_DIR}/%p.txt"

# Determine if we need to do data validation checks.
VALIDATION=0
if [[ "$DATA_CHECK" == "true" ]]; then
  VALIDATION=1
fi

$NSYS_PREFIX \
taskset -c "$UNRESERVED_CORES" \
  /third_party/nccl-tests-mpi/build/run_colls \
    -b 0 -e 8G -f 2 -g 1 -w 0 --iters "$N_COMMS" -c "$VALIDATION" \
    -l "${SCRIPT_DIR}/benchmark_input"

# Kernel diagnostics (dmesg).
if [[ "$OMPI_COMM_WORLD_LOCAL_RANK" == "0" && \
      "$KERNEL_TELEMETRY" == "true" ]]; then
  KERNEL_TELEMETRY_DIR="${TELEMETRY_DIR}/kernel"
  mkdir -p "$KERNEL_TELEMETRY_DIR"

  dmesg > "${KERNEL_TELEMETRY_DIR}/dmesg.txt"
fi

# NIC telemetry (ethtool).
if [[ "$OMPI_COMM_WORLD_LOCAL_RANK" == "0" && \
      "$NIC_TELEMETRY" == "true" ]]; then
  NIC_TELEMETRY_DIR="${TELEMETRY_DIR}/nic"
  ETHTOOL_DIR="${NIC_TELEMETRY_DIR}/ethtool"
  mkdir -p "$ETHTOOL_DIR"

  for IF in ${ALL_IFS[@]}; do
    ethtool -S "$IF" > "${ETHTOOL_DIR}/${IF}.txt"
  done
fi

# Kill all background processes collecting telemetry.
if [[ "$OMPI_COMM_WORLD_LOCAL_RANK" == "0" ]]; then
  kill $(jobs -p) 2> /dev/null || true
fi
