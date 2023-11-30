#! /bin/bash
set -e
set -u
set -o pipefail

: "${MASTER_ADDR:?Must set MASTER_ADDR}"
: "${NODE_RANK:?Must set NODE_RANK}"
: "${NNODES:?Must set NNODES}"
: "${MASTER_PORT:?Must set MASTER_PORT}"
: "${WORLD_SIZE:?Must set WORLD_SIZE}"
: "${NUM_BATCHES:=12}"
: "${BATCH_SIZE:?Must set BATCH_SIZE}"
: "${DTMS:?Must set DTMS}"
: "${DTMS:?Must set MAX_SEQ_LEN}"

export EXPERIMENT_LOCAL_DIR="/experiment"
export EXPERIMENT_ROOT_DIR=${MODEL_NAME}_${NNODES}nodes
export GPUS_PER_NODE=8
export LOCAL_WORLD_SIZE=$GPUS_PER_NODE

PYTHONUNBUFFERED=1
NCCL_ASYNC_ERROR_HANDLING=1

mkdir $EXPERIMENT_LOCAL_DIR
gsutil rsync -r -C gs://${GCS_BUCKET}/${EXPERIMENT_ROOT_DIR}/${JOB_TIMESTAMP}/ ${EXPERIMENT_LOCAL_DIR}/

PROFILING_DIR=$EXPERIMENT_LOCAL_DIR/nsys_profiles
mkdir -p $PROFILING_DIR

LOG_DIR=$EXPERIMENT_LOCAL_DIR/training_logs
mkdir -p $LOG_DIR

OUT_DIR=$EXPERIMENT_LOCAL_DIR/out
mkdir -p $OUT_DIR

DEBUG_DIR=$EXPERIMENT_LOCAL_DIR/debug
mkdir -p $DEBUG_DIR

# TELEMETRY_DIR=$EXPERIMENT_LOCAL_DIR/telemetry
# mkdir -p $TELEMETRY_DIR
# mpstat -P ALL 1 &> $TELEMETRY_DIR/mpstat_NODE_${NODE_RANK}.txt &
# MPSTAT_PID=$!

CMD_PREFIX=""

export NCCL_TOPO_DUMP_FILE=$DEBUG_DIR/nccl_topo_${NODE_RANK}.xml
export NCCL_GRAPH_DUMP_FILE="$DEBUG_DIR/nccl_graph_${NODE_RANK}.graph"

set_nccl_specific_configuration() {
  if [[ "$USE_TCPX" == "yes" ]]; then
    echo "Using TCPX"
    export NCCL_CROSS_NIC=0
    export NCCL_ALGO=Ring
    export NCCL_PROTO=Simple
    export NCCL_NET_GDR_LEVEL=PIX
    export NCCL_P2P_PXN_LEVEL=0
    export NCCL_DEBUG_SUBSYS=INIT,GRAPH,ENV,TUNING,NET,VERSION
    export NCCL_DEBUG=INFO
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
export OMP_NUM_THREADS=12

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
   touch /usr/share/mpt/workload_terminated
   kill -9 $MPSTAT_PID

   echo "Uploading ${EXPERIMENT_LOCAL_DIR} to gs://${GCS_BUCKET}/${EXPERIMENT_ROOT_DIR}/${JOB_TIMESTAMP}/"
   # echo "SKIPPING UPLOAD, STORAGE NOT CONFIGURED"
   gsutil rsync -r ${EXPERIMENT_LOCAL_DIR}/ gs://${GCS_BUCKET}/${EXPERIMENT_ROOT_DIR}/${JOB_TIMESTAMP}/
}


rm -f /usr/share/mpt/workload_terminated

trap on_script_completion EXIT


if [[ "${DISABLE_PMTU:="yes"}" == "yes" ]]; then
  echo "Disabling PMTU"
  sysctl -w net.ipv4.tcp_mtu_probing=0
else
  echo "Enabling PMTU"
  sysctl -w net.ipv4.tcp_mtu_probing=1
fi

PIDS=()


CPU_SETS=( "0-7,104-111" "8-15,112-119" "16-23,120-127" "24-31,128-135" "52-59,156-163" "60-67,164-171" "68-75,172-179" "76-83,180-187" )

YAML_FILE=/llm-foundry/scripts/train/yamls/pretrain/${MODEL_NAME}.yaml

cat $YAML_FILE
printenv

echo "Preparing dataset for seqLen: " $MAX_SEQ_LEN
python data_prep/convert_dataset_hf.py \
  --dataset c4 --data_subset en \
  --out_root my-copy-c4 --splits train_small val_small \
  --concat_tokens $MAX_SEQ_LEN --tokenizer EleutherAI/gpt-neox-20b --eos_text '<|endoftext|>'

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
  elif [[ "${COLLECT_COMPOSER_PROFILE:="no"}" == "yes" ]]; then
    export USE_CUSTOM_PROFILER='yes'
  fi


   RANK=$RANK LOCAL_RANK=$LOCAL_RANK \
     $CMD_PREFIX \
     python train/train.py $YAML_FILE \
     data_local=my-copy-c4 \
     train_loader.dataset.split=train_small \
     eval_loader.dataset.split=val_small max_duration=${NUM_BATCHES}ba eval_interval=0 \
     fsdp_config.activation_checkpointing=${ACT_CKPT} \
     model.n_layers=${N_LAYERS} \
     model.max_seq_len=${MAX_SEQ_LEN} \
     global_train_batch_size=${BATCH_SIZE} \
     device_train_microbatch_size=${DTMS} \
     callbacks.speed_monitor.gpu_flops_available=989500000000000 \
     > >(tee "$LOG_DIR/pretrain_mpt_rank$RANK.log") 2>&1 &

   PID=$!
   PIDS+=($PID)

   echo "Launched pretrain_gpt.py for rank $RANK with PID $PID"
done

wait_all_success_or_exit "${PIDS[@]}"