#!/bin/bash

# Job parameters.
: "${RUN_LOG_DIR:?Must set RUN_LOG_DIR}"

# Benchmark parameters.
: "${N_COMMS:?Must set N_COMMS}"

# Unreserved cores for taskset call. This is a CSV of ranges for cores unused
# by TCPX.
: "${UNRESERVED_CORES:?Must set UNRESERVED_CORES}"

# Telemetry.
: "${GPU_TELEMETRY:?Must set GPU_TELEMETRY}"

# OpenMPI parameters.
: "${OMPI_COMM_WORLD_RANK:?Must set OMPI_COMM_WORLD_RANK}"
: "${OMPI_COMM_WORLD_LOCAL_SIZE:?Must set OMPI_COMM_WORLD_LOCAL_SIZE}"
: "${OMPI_COMM_WORLD_LOCAL_RANK:?Must set OMPI_COMM_WORLD_LOCAL_RANK}"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Compute node rank based on global rank and local world size.
# This is a workaround for us not being able to send this info directly in MPI.
NODE_RANK=$(( OMPI_COMM_WORLD_RANK / OMPI_COMM_WORLD_LOCAL_SIZE ))

TELEMETRY_DIR="${RUN_LOG_DIR}/telemetry/node${NODE_RANK}"
# Add GPU profiling.
NSYS_PREFIX=""
if [[ "$GPU_TELEMETRY" == "true" ]]; then
  GPU_TELEMETRY_DIR="${TELEMETRY_DIR}/gpu"
  mkdir -p "$GPU_TELEMETRY_DIR"
  GPU_TELEMETRY_OUTPUT="${GPU_TELEMETRY_DIR}/rank${OMPI_COMM_WORLD_LOCAL_RANK}"
  NSYS_PREFIX="nsys profile \
                  --wait primary -o ${GPU_TELEMETRY_OUTPUT} \
                  --force-overwrite true -t cuda,nvtx -s none --export sqlite"
fi

$NSYS_PREFIX \
taskset -c "$UNRESERVED_CORES" \
  /third_party/nccl-tests-mpi/build/all_gather_perf \
    -b 1G -e 8G -f 2 -g 1 -w 0 --iters "$N_COMMS" -c 0
    # -l "${SCRIPT_DIR}/benchmark_input"