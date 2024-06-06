#!/bin/bash

set -x
export NCCL_SOCKET_IFNAME=enp0s12
export NCCL_CROSS_NIC=0
export NCCL_ALGO=Ring
export NCCL_PROTO=Simple
export NCCL_NSOCKS_PERTHREAD=4
export NCCL_SOCKET_NTHREADS=1
export NCCL_MAX_NCHANNELS=12
export NCCL_MIN_NCHANNELS=12
export NCCL_DYNAMIC_CHUNK_SIZE=524288
export NCCL_P2P_NET_CHUNKSIZE=524288
export NCCL_P2P_PCI_CHUNKSIZE=524288
export NCCL_P2P_NVL_CHUNKSIZE=1048576
export NCCL_BUFFSIZE=4194304
export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export NCCL_GPUDIRECTTCPX_SOCKET_IFNAME=enp6s0,enp12s,enp134s0,enp140s0
export NCCL_GPUDIRECTTCPX_CTRL_DEV=enp0s12
export NCCL_NET_GDR_LEVEL=PIX
export NCCL_P2P_PXN_LEVEL=0
#export NCCL_DEBUG=INFO
#export NCCL_DEBUG_SUBSYS=ENV
export NCCL_GPUDIRECTTCPX_UNIX_CLIENT_PREFIX=/run/tcpx-${SLURM_JOB_ID}
export NCCL_GPUDIRECTTCPX_PROGRAM_FLOW_STEERING_WAIT_MICROS=1000000
export NCCL_GPUDIRECTTCPX_FORCE_ACK=0
export NCCL_GPUDIRECTTCPX_TX_COMPLETION_NANOSLEEP=1000

# Below seems to work even when no smt is enabled
export NCCL_GPUDIRECTTCPX_TX_BINDINGS="enp6s0:8-21,112-125;enp12s0:8-21,112-125;enp134s0:60-73,164-177;enp140s0:60-73,164-177"
export NCCL_GPUDIRECTTCPX_RX_BINDINGS="enp6s0:22-35,124-139;enp12s0:22-35,124-139;enp134s0:74-87,178-191;enp140s0:74-87,178-191"

# App specific
export LD_LIBRARY_PATH=/usr/local/nvidia/lib64:/var/lib/tcpx/lib64:/usr/lib/lib32:/usr/lib/x86_64-linux-gnu/ \

export JOB_TIMESTAMP=1
export MASTER_ADDR=$SLURM_LAUNCH_NODE_IPADDR
export NNODES=$SLURM_NNODES
export NODE_RANK=$SLURM_PROCID
export WORLD_SIZE=$SLURM_NTASKS
export MASTER_PORT=6000

# yes sets wrong NCCL variables for Compute Engine VM!
# https://github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning/blob/d02347ab80ed327cb43ed82fd28acfacbf4e43cb/sample_workloads/lit-gpt-demo/scripts/litgpt_container_entrypoint.sh#L47
export USE_TCPX=no

python trainer_dpp.py --world-size 2
