# Check for required environment variables
if [ -z "$MODEL_NAME" ]; then
  echo "Error: MODEL_NAME environment variable is not set. Please set it before running the script."
  exit 1
fi

if [ -z "$GCS_EXPERIMENT_BUCKET" ]; then
  echo "Error: GCS_EXPERIMENT_BUCKET environment variable is not set. Please set it before running the script."
  exit 1
fi

if [ -z "$EXPERIMENT_ROOT_DIR" ]; then
  echo "Error: EXPERIMENT_ROOT_DIR environment variable is not set. Please set it before running the script."
  exit 1
fi

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
    -e MODEL_NAME=${MODEL_NAME} \
    -e GCS_EXPERIMENT_BUCKET=${GCS_EXPERIMENT_BUCKET} \
    -e GCS_DATA_BUCKET=litgpt-public-bucket \
    -e USE_TCPX=yes \
    -e CLUSTER_TYPE=SLURM \
    -e EXPERIMENT_ROOT_DIR=${EXPERIMENT_ROOT_DIR} \
    -e DATA_DIR=openwebtext_dataset \
    -e MASTER_ADDR=$MASTER_ADDR \
    -e MASTER_PORT=20120 \
    -e NCCL_GPUDIRECTTCPX_UNIX_CLIENT_PREFIX=${UDS_PATH} \
    -e WARMUP_ITERS=10 \
    -e MAX_ITERS=1000 \
    us-docker.pkg.dev/gce-ai-infra/litgpt-full/litgpt:slurm
