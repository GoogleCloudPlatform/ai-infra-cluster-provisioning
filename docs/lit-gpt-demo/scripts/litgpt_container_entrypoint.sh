#! /bin/bash
set -e
set -u
set -o pipefail

: "${MASTER_ADDR:?Must set MASTER_ADDR}"
: "${NODE_RANK:?Must set NODE_RANK}"
: "${GCS_BUCKET:?Must set GCS_BUCKET}"
: "${JOB_TIMESTAMP:?Must set JOB_TIMESTAMP}"
: "${EXPERIMENT_ROOT_DIR:?Must set EXPERIMENT_ROOT_DIR}"
: "${NNODES:?Must set NNODES}"
: "${DATA_DIR:?Must set DATA_DIR}"

EXPERIMENT_LOCAL_DIR=/experiment/${EXPERIMENT_ROOT_DIR}
mkdir -p $EXPERIMENT_LOCAL_DIR

echo $EXPERIMENT_ROOT_DIR
echo $EXPERIMENT_LOCAL_DIR

gsutil rsync -r gs://${GCS_BUCKET}/${EXPERIMENT_ROOT_DIR}/ ${EXPERIMENT_LOCAL_DIR}/

LOCAL_DATA_DIR=/data
mkdir -p $LOCAL_DATA_DIR
gsutil -m rsync gs://${GCS_BUCKET}/${DATA_DIR} /data

export MASTER_PORT=6002
export GPUS_PER_NODE=8
export WORLD_SIZE=$((NNODES * GPUS_PER_NODE))

PROFILING_DIR=$EXPERIMENT_LOCAL_DIR/nsys_profiles
mkdir -p $PROFILING_DIR

LOG_DIR=$EXPERIMENT_LOCAL_DIR/training_logs
mkdir -p $LOG_DIR

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
    export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/local/tcpx/lib64"
    export NCCL_GPUDIRECTTCPX_FORCE_ACK=1
    export NCCL_GPUDIRECTTCPX_TX_COMPLETION_NANOSLEEP=1000
    export NCCL_SOCKET_IFNAME=eth0
    export NCCL_DYNAMIC_CHUNK_SIZE=524288
    export NCCL_P2P_NET_CHUNKSIZE=524288
    export NCCL_P2P_PCI_CHUNKSIZE=524288
    export NCCL_P2P_NVL_CHUNKSIZE=1048576
    export NCCL_GPUDIRECTTCPX_TX_BINDINGS="eth1:8-21,112-125;eth2:8-21,112-125;eth3:60-73,164-177;eth4:60-73,164-177"
    export NCCL_GPUDIRECTTCPX_RX_BINDINGS="eth1:22-35,124-139;eth2:22-35,124-139;eth3:74-87,178-191;eth4:74-87,178-191"
    export NCCL_NSOCKS_PERTHREAD=4
    export NCCL_SOCKET_NTHREADS=1
    export NCCL_MAX_NCHANNELS=8
    export NCCL_MIN_NCHANNELS=8
    export NCCL_GPUDIRECTTCPX_SOCKET_IFNAME=eth1,eth2,eth3,eth4
    export NCCL_GPUDIRECTTCPX_CTRL_DEV=eth0
    export NCCL_GPUDIRECTTCPX_PROGRAM_FLOW_STEERING_WAIT_MICROS=1000000

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
   # semaphore to cleanly exit hardware utilization monitor
   touch /tmp/workload_terminated

   echo "Uploading ${EXPERIMENT_LOCAL_DIR} to gs://${GCS_BUCKET}/${EXPERIMENT_ROOT_DIR}/"
   gsutil rsync -r ${EXPERIMENT_LOCAL_DIR}/ gs://${GCS_BUCKET}/${EXPERIMENT_ROOT_DIR}/
}


trap on_script_completion EXIT

# Launch background process that samples hardware utilization
rm -f /tmp/workload_terminated

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


   RANK=$RANK LOCAL_RANK=$LOCAL_RANK \
     $CMD_PREFIX \
     python /workspace/pretrain/openwebtext_trainer.py \
     --devices=$GPUS_PER_NODE > >(tee "$LOG_DIR/pretrain_gpt_rank$RANK.log") 2>&1 &
   PID=$!
   PIDS+=($PID)

   echo "Launched pretrain_gpt.py for rank $RANK with PID $PID"
done

wait_all_success_or_exit "${PIDS[@]}"
