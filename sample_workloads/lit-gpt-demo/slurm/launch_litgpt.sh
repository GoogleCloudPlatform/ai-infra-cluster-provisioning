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

# Start rxdm container
srun --ntasks-per-node=1 \
    docker run \
    --pull=always \
    --detach \
    --rm \
    --name receive-datapath-manager-${SLURM_JOB_ID} \
    --privileged \
    --cap-add=NET_ADMIN \
    --network=host \
    --gpus all \
    --volume /var/lib/nvidia/lib64:/usr/local/nvidia/lib64 \
    --volume ${GPU_NIC_TOPOLOGY_DIR}:${GPU_NIC_TOPOLOGY_DIR} \
    --volume ${UDS_PATH}:${UDS_PATH} \
    --env LD_LIBRARY_PATH=/usr/local/nvidia/lib64:${UDS_PATH}:/usr/lib/lib32:/usr/lib/x86_64-linux-gnu/ \
    --entrypoint /tcpgpudmarxd/build/app/tcpgpudmarxd \
    us-docker.pkg.dev/gce-ai-infra/gpudirect-tcpx/tcpgpudmarxd-dev:v2.0.7 \
    --setup_param "--verbose 128 2 0" \
    --gpu_nic_preset manual \
    --gpu_nic_topology ${GPU_NIC_TOPOLOGY} \
    --gpu_shmem_type fd \
    --uds_path ${UDS_PATH}

# Lauch the litgpt script
srun -l --ntasks-per-node=1 bash litgpt.sh

# Stop rxdm container
srun --ntasks-per-node=1 docker container stop receive-datapath-manager-${SLURM_JOB_ID}