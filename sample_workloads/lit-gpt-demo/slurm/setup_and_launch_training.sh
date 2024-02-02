#!/bin/bash
#
#SBATCH --partition=a3
#SBATCH --exclusive
#SBATCH --gpus-per-node 8
#SBATCH --nodes 4

export UDS_PATH="/run/tcpx-${SLURM_JOB_ID}"
GPU_NIC_TOPOLOGY=/opt/tcpdirect_benchmark/gpu_rxq_configuration.textproto
GPU_NIC_TOPOLOGY_DIR=`dirname ${GPU_NIC_TOPOLOGY}`

if [ ! -f "${GPU_NIC_TOPOLOGY}" ]; then
        echo "GPU_NIC_TOPOLOGY file ${GPU_NIC_TOPOLOGY} must exist!"
        exit 1
fi

# Install NCCL plugin
srun --ntasks-per-node=1 \
    docker run --rm -v /var/lib:/var/lib \
    us-docker.pkg.dev/gce-ai-infra/gpudirect-tcpx/nccl-plugin-gpudirecttcpx-dev:v3.1.6_2023_10_06 install --install-nccl

# Configure Docker
srun --ntasks-per-node=1 \
    gcloud auth configure-docker us-central1-docker.pkg.dev

# Launch the litgpt script
srun -l --ntasks-per-node=1 bash litgpt_container.sh
