#! /bin/bash
set -e
set -u
set -o pipefail

: "${MASTER_ADDR:?Must set MASTER_ADDR}"
: "${NODE_RANK:?Must set NODE_RANK}"
: "${JOB_TIMESTAMP:?Must set JOB_TIMESTAMP}"
: "${NNODES:?Must set NNODES}"
: "${EXPERIMENT_ROOT_DIR:?Must set EXPERIMENT_ROOT_DIR}"
: "${GCS_DATA_BUCKET:?Must set GCS_DATA_BUCKET}"
: "${DATA_DIR:?Must set DATA_DIR}"
: "${GCS_EXPERIMENT_BUCKET:=''}"
: "${CLUSTER_TYPE:='GKE'}"
: "${COLLECT_NSYS_PROFILE:='no'}"
: "${NCCL_DEBUG:='INFO'}"

export EXPERIMENT_LOCAL_DIR=/experiment/${EXPERIMENT_ROOT_DIR}

mkdir -p $EXPERIMENT_LOCAL_DIR

echo $EXPERIMENT_ROOT_DIR
echo $EXPERIMENT_LOCAL_DIR

if [[ -z $GCS_EXPERIMENT_BUCKET ]]; then
  echo "Disabling gsutil calls. Not syncing experiment dir."
else
  gsutil -m rsync -r gs://${GCS_EXPERIMENT_BUCKET}/${EXPERIMENT_ROOT_DIR}/ ${EXPERIMENT_LOCAL_DIR}/
fi

LOCAL_DATA_DIR=/data
mkdir -p $LOCAL_DATA_DIR
gsutil -m rsync gs://${GCS_DATA_BUCKET}/${DATA_DIR} /data

export MASTER_PORT=6002
export GPUS_PER_NODE=8
export WORLD_SIZE=$((NNODES * GPUS_PER_NODE))

LOG_DIR=$EXPERIMENT_LOCAL_DIR/training_logs
mkdir -p $LOG_DIR

PROFILING_DIR=$EXPERIMENT_LOCAL_DIR/nsys_profiles
mkdir -p $PROFILING_DIR

OUT_DIR=$EXPERIMENT_LOCAL_DIR/out
mkdir -p $OUT_DIR

DEBUG_DIR=$EXPERIMENT_LOCAL_DIR/debug
mkdir -p $DEBUG_DIR

export NCCL_TOPO_DUMP_FILE=$DEBUG_DIR/nccl_topo_${JOB_TIMESTAMP}_${NODE_RANK}.xml
export NCCL_GRAPH_DUMP_FILE="$DEBUG_DIR/nccl_graph_${JOB_TIMESTAMP}_${NODE_RANK}.graph"

export OMP_NUM_THREADS=12

set_nccl_specific_configuration() {
  if [[ "$USE_TCPX" == "yes" ]]; then
    echo "Using TCPX"
    export NCCL_CROSS_NIC=0
    export NCCL_ALGO=Ring
    export NCCL_PROTO=Simple
    export NCCL_NET_GDR_LEVEL=PIX
    export NCCL_P2P_PXN_LEVEL=0
    export NCCL_DEBUG_SUBSYS=INIT,GRAPH,ENV,TUNING,NET,VERSION
    export NCCL_DEBUG=${NCCL_DEBUG}
    export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/local/tcpx/lib64"
    export NCCL_GPUDIRECTTCPX_FORCE_ACK=1
    export NCCL_GPUDIRECTTCPX_TX_COMPLETION_NANOSLEEP=1000
    export NCCL_DYNAMIC_CHUNK_SIZE=524288
    export NCCL_P2P_NET_CHUNKSIZE=524288
    export NCCL_P2P_PCI_CHUNKSIZE=524288
    export NCCL_P2P_NVL_CHUNKSIZE=1048576
    export NCCL_NSOCKS_PERTHREAD=4
    export NCCL_SOCKET_NTHREADS=1
    export NCCL_MAX_NCHANNELS=8
    export NCCL_MIN_NCHANNELS=8
    export NCCL_GPUDIRECTTCPX_PROGRAM_FLOW_STEERING_WAIT_MICROS=1000000
    export NCCL_SOCKET_IFNAME=eth0
    export NCCL_GPUDIRECTTCPX_TX_BINDINGS="eth1:8-21,112-125;eth2:8-21,112-125;eth3:60-73,164-177;eth4:60-73,164-177"
    export NCCL_GPUDIRECTTCPX_RX_BINDINGS="eth1:22-35,126-139;eth2:22-35,126-139;eth3:74-87,178-191;eth4:74-87,178-191"
    export NCCL_GPUDIRECTTCPX_SOCKET_IFNAME=eth1,eth2,eth3,eth4
    export NCCL_GPUDIRECTTCPX_CTRL_DEV=eth0
    if [[ "$CLUSTER_TYPE" == "SLURM" ]]; then
      echo "Overriding with SLURM Specific Envvar"
      export NCCL_SOCKET_IFNAME=enp0s12 
      export NCCL_GPUDIRECTTCPX_TX_BINDINGS="enp6s0:8-21,112-125;enp12s0:8-21,112-125;enp134s0:60-73,164-177;enp140s0:60-73,164-177"
      export NCCL_GPUDIRECTTCPX_RX_BINDINGS="enp6s0:22-35,126-139;enp12s0:22-35,126-139;enp134s0:74-87,178-191;enp140s0:74-87,178-191"
      export NCCL_GPUDIRECTTCPX_SOCKET_IFNAME=enp6s0,enp12s,enp134s0,enp140s0
      export NCCL_GPUDIRECTTCPX_CTRL_DEV=enp0s12
    fi
  else
    echo "NOT using TCPX"
  fi
}

set_nccl_specific_configuration

wait_all_success_or_exit() {
  # https://www.baeldung.com/linux/background-process-get-exit-code
  local pids=("$@")
  while [[ ${#pids[@]} -ne 0 ]]; do
    all_success="true"
    for pid in "${pids[@]}"; do
      code=$(non_blocking_wait "$pid")
      if [[ $code -ne 127 ]]; then
        if [[ $code -ne 0 ]]; then
          echo "PID $pid failed with exit code $code"
          exit "$code"
        fi
      else
        all_success="false"
      fi
    done
    if [[ $all_success == "true" ]]; then
      echo "All pids succeeded"
      break
    fi
    sleep 5
  done
}

non_blocking_wait() {
  # https://www.baeldung.com/linux/background-process-get-exit-code
  local pid=$1
  local code=127 # special code to indicate not-finished
  if [[ ! -d "/proc/$pid" ]]; then
    wait "$pid"
    code=$?
  fi
  echo $code
}

function on_script_completion {
   if [[ -z $GCS_EXPERIMENT_BUCKET ]]; then
    echo "Disabling gsutil. Not uploading logs."
  else
    echo "Uploading ${EXPERIMENT_LOCAL_DIR} to gs://${GCS_EXPERIMENT_BUCKET}/${EXPERIMENT_ROOT_DIR}/"
    gsutil rsync -r ${EXPERIMENT_LOCAL_DIR}/ gs://${GCS_EXPERIMENT_BUCKET}/${EXPERIMENT_ROOT_DIR}/
  fi

  # semaphore to cleanly exit hardware utilization monitor
  echo "Writing semaphore to exit sidecar container to /usr/share/litgpt/workload_terminated"
  touch /usr/share/litgpt/workload_terminated

  METRICS_FILE=$EXPERIMENT_LOCAL_DIR/out/version_0/metrics.csv
  if test -f $METRICS_FILE; then
    echo "Printing out metrics.csv results from $METRICS_FILE"
    cat $EXPERIMENT_LOCAL_DIR/out/version_0/metrics.csv
  else
    echo "Metrics.csv not located at $METRICS_FILE"
  fi
}


trap on_script_completion EXIT

# Launch background process that samples hardware utilization
rm -f /usr/share/litgpt/workload_terminated

if [[ "${DISABLE_PMTU:="yes"}" == "yes" ]]; then
  echo "Disabling PMTU"
  sysctl -w net.ipv4.tcp_mtu_probing=0
else
  echo "Enabling PMTU"
  sysctl -w net.ipv4.tcp_mtu_probing=1
fi

PIDS=()

CPU_SETS=( "0-7,104-111" "8-15,112-119" "16-23,120-127" "24-31,128-135" "52-59,156-163" "60-67,164-171" "68-75,172-179" "76-83,180-187" )

for ((LOCAL_RANK=0; LOCAL_RANK <= $((GPUS_PER_NODE - 1)); LOCAL_RANK++)); do
   RANK=$(($GPUS_PER_NODE*$NODE_RANK + $LOCAL_RANK))

   CPUS=${CPU_SETS[$LOCAL_RANK]}
   echo "Using CPUs $CPUS for local rank $LOCAL_RANK"

   if (( LOCAL_RANK < 4 )); then
     MEMBIND_NUMA_NODE=0
   else
     MEMBIND_NUMA_NODE=1
   fi
   CMD_PREFIX="numactl --membind=$MEMBIND_NUMA_NODE --physcpubind $CPUS"

   if [[ "${COLLECT_NSYS_PROFILE:="no"}" == "yes" ]]; then
     echo "Collecting nsys profile"
     CMD_PREFIX="${CMD_PREFIX} nsys profile --sample=none --trace=cuda,nvtx -o $PROFILING_DIR/node_${NODE_RANK:?}_local_rank_${LOCAL_RANK} --capture-range=cudaProfilerApi --capture-range-end=repeat:${PROFILE_REPS:=5} --export sqlite "
   fi

   RANK=$RANK LOCAL_RANK=$LOCAL_RANK \
     $CMD_PREFIX \
     python /workspace/pretrain/openwebtext.py \
     --devices=$GPUS_PER_NODE --precision="bf16-true" --model_name="$MODEL_NAME" > >(tee "$LOG_DIR/pretrain_gpt_rank$RANK.log") 2>&1 &
   PID=$!
   PIDS+=($PID)

   echo "Launched openwebtext.py for rank $RANK with PID $PID"
done

wait_all_success_or_exit "${PIDS[@]}"