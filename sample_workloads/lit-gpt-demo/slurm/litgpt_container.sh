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
    -e GCS_EXPERIMENT_BUCKET=litgpt-public-bucket \
    -e GCS_DATA_BUCKET=litgpt-public-bucket \
    -e USE_TCPX=yes \
    -e CLUSTER_TYPE=SLURM \
    -e EXPERIMENT_ROOT_DIR=llama-70b/training_logs \
    -e DATA_DIR=openwebtext_dataset \
    -e MASTER_ADDR=$MASTER_ADDR \
    -e MASTER_PORT=20120 \
    -e NCCL_GPUDIRECTTCPX_UNIX_CLIENT_PREFIX=${UDS_PATH} \
    us-docker.pkg.dev/gce-ai-infra/litgpt-full/litgpt:slurm