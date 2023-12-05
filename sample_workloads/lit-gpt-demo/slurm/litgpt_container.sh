MASTER_ADDR=$(scontrol show hostnames "$SLURM_JOB_NODELIST" | head -n 1)

# Start the Lit-GPT training container
docker run \
    --privileged \
    --gpus all --net="host" \
    -v /var/lib/tcpx/lib64:/var/lib/tcpx/lib64 \
    -v ${UDS_PATH}:${UDS_PATH} \
    -u 0 \
    -e LD_LIBRARY_PATH=/usr/local/nvidia/lib64:/var/lib/tcpx/lib64:/usr/lib/lib32:/usr/lib/x86_64-linux-gnu/ \
    -e JOB_TIMESTAMP=$(date +%s) \
    -e NNODES=$SLURM_NNODES \
    -e NODE_RANK=$SLURM_NODEID \
    -e MODEL_NAME='Llama-2-70b-hf' \
    -e GCS_BUCKET=litgpt-public-bucket \
    -e USE_TCPX=no \
    -e EXPERIMENT_ROOT_DIR=tejasn_nama/training_logs \
    -e DATA_DIR=openwebtext_dataset \
    -e MASTER_ADDR=$MASTER_ADDR \
    -e MASTER_PORT=20120 \
    -e NCCL_SOCKET_IFNAME=enp0s12 \
    -e NCCL_CROSS_NIC=0 \
    -e NCCL_ALGO=Ring \
    -e NCCL_PROTO=Simple \
    -e NCCL_NSOCKS_PERTHREAD=4 \
    -e NCCL_SOCKET_NTHREADS=1 \
    -e NCCL_MAX_NCHANNELS=12 \
    -e NCCL_MIN_NCHANNELS=12 \
    -e NCCL_DYNAMIC_CHUNK_SIZE=524288 \
    -e NCCL_P2P_NET_CHUNKSIZE=524288 \
    -e NCCL_P2P_PCI_CHUNKSIZE=524288 \
    -e NCCL_P2P_NVL_CHUNKSIZE=1048576 \
    -e NCCL_BUFFSIZE=4194304 \
    -e CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 \
    -e NCCL_GPUDIRECTTCPX_SOCKET_IFNAME=enp6s0,enp12s,enp134s0,enp140s0 \
    -e NCCL_GPUDIRECTTCPX_CTRL_DEV=enp0s12 \
    -e NCCL_NET_GDR_LEVEL=PIX \
    -e NCCL_P2P_PXN_LEVEL=0 \
    -e NCCL_GPUDIRECTTCPX_UNIX_CLIENT_PREFIX=${UDS_PATH} \
    -e NCCL_GPUDIRECTTCPX_PROGRAM_FLOW_STEERING_WAIT_MICROS=1000000 \
    -e NCCL_GPUDIRECTTCPX_FORCE_ACK=0 \
    -e NCCL_GPUDIRECTTCPX_TX_COMPLETION_NANOSLEEP=1000 \
    -e NCCL_GPUDIRECTTCPX_TX_BINDINGS="enp6s0:8-21,112-125;enp12s0:8-21,112-125;enp134s0:60-73,164-177;enp140s0:60-73,164-177" \
    -e NCCL_GPUDIRECTTCPX_RX_BINDINGS="enp6s0:22-35,124-139;enp12s0:22-35,124-139;enp134s0:74-87,178-191;enp140s0:74-87,178-191" \
    -e NCCL_DEBUG=WARN \
    us-docker.pkg.dev/gce-ai-infra/litgpt-full/litgpt:latest