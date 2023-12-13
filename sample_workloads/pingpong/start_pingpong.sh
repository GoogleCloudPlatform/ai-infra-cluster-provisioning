#! /bin/bash
set -e
set -u
set -o pipefail

: "${MASTER_ADDR:?Must set MASTER_ADDR}"
: "${MASTER_PORT:?Must set MASTER_PORT}"
: "${NODE_RANK:?Must set NODE_RANK}"
: "${NNODES:?Must set NNODES}"
: "${GPUS_PER_NODE:?Must set GPUS_PER_NODE}"

export GPUS_PER_NODE=$GPUS_PER_NODE

set_nccl_gpudirect_tcpx_specific_configuration() {
  if [[ "$USE_GPUDIRECT_TCPX" == "yes" ]]; then
    echo "Using GPUDirect-TCPX"
    export NCCL_CROSS_NIC=0
    export NCCL_ALGO=Ring
    export NCCL_PROTO=Simple
    # export NCCL_DEBUG=INFO
    export NCCL_NET_GDR_LEVEL=PIX
    export NCCL_P2P_PXN_LEVEL=0
    export NCCL_DEBUG_SUBSYS=INIT,GRAPH,ENV,TUNING,NET,VERSION
    export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/local/tcpx/lib64"
    export NCCL_GPUDIRECTTCPX_FORCE_ACK=0
    export NCCL_GPUDIRECTTCPX_TX_COMPLETION_NANOSLEEP=1000
    export NCCL_DYNAMIC_CHUNK_SIZE=524288
    export NCCL_P2P_NET_CHUNKSIZE=524288
    export NCCL_P2P_PCI_CHUNKSIZE=524288
    export NCCL_P2P_NVL_CHUNKSIZE=1048576
    export NCCL_NSOCKS_PERTHREAD=4
    export NCCL_SOCKET_NTHREADS=1
    export NCCL_MAX_NCHANNELS=12
    export NCCL_MIN_NCHANNELS=12
    export NCCL_GPUDIRECTTCPX_PROGRAM_FLOW_STEERING_WAIT_MICROS=1000000
    export NCCL_SOCKET_IFNAME=eth0
    export NCCL_GPUDIRECTTCPX_TX_BINDINGS="eth1:8-21,112-125;eth2:8-21,112-125;eth3:60-73,164-177;eth4:60-73,164-177"
    export NCCL_GPUDIRECTTCPX_RX_BINDINGS="eth1:22-35,124-139;eth2:22-35,124-139;eth3:74-87,178-191;eth4:74-87,178-191"
    export NCCL_GPUDIRECTTCPX_SOCKET_IFNAME=eth1,eth2,eth3,eth4
    export NCCL_GPUDIRECTTCPX_CTRL_DEV=eth0
    if [[ "$CLUSTER_TYPE" == "SLURM" ]]; then
      echo "Overriding with SLURM Specific Envvar"
      export NCCL_SOCKET_IFNAME=enp0s12 
      export NCCL_GPUDIRECTTCPX_TX_BINDINGS="enp6s0:8-21,112-125;enp12s0:8-21,112-125;enp134s0:60-73,164-177;enp140s0:60-73,164-177"
      export NCCL_GPUDIRECTTCPX_RX_BINDINGS="enp6s0:22-35,124-139;enp12s0:22-35,124-139;enp134s0:74-87,178-191;enp140s0:74-87,178-191"
      export NCCL_GPUDIRECTTCPX_SOCKET_IFNAME=enp6s0,enp12s,enp134s0,enp140s0
      export NCCL_GPUDIRECTTCPX_CTRL_DEV=enp0s12
    fi
  else
    echo "NOT using TCPX"
  fi
}

set_nccl_gpudirect_tcpx_specific_configuration

echo "Starting . . . $MASTER_ADDR:$MASTER_PORT" 
python -u -m torch.distributed.run --nnodes=$NNODES --node_rank=$NODE_RANK --nproc_per_node=$GPUS_PER_NODE --rdzv_endpoint $MASTER_ADDR:$MASTER_PORT  --rdzv_backend c10d pingpong.py
touch /tmp/workload_terminated
echo "Done . . ."