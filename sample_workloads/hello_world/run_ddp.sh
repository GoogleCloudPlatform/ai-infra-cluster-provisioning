#!/bin/bash
#
#SBATCH --partition=a3
#SBATCH --exclusive
#SBATCH --gpus-per-node 8
#SBATCH --nodes 2

UDS_PATH="/run/tcpx-${SLURM_JOB_ID}"
GPU_NIC_TOPOLOGY=/opt/tcpdirect_benchmark/gpu_rxq_configuration.textproto
GPU_NIC_TOPOLOGY_DIR=`dirname ${GPU_NIC_TOPOLOGY}`

if [ ! -f "${GPU_NIC_TOPOLOGY}" ]; then
        echo "GPU_NIC_TOPOLOGY file ${GPU_NIC_TOPOLOGY} must exist!"
        exit 1
fi

srun --ntasks-per-node=1 \
    docker run --rm -v /var/lib:/var/lib \
    us-docker.pkg.dev/gce-ai-infra/gpudirect-tcpx/nccl-plugin-gpudirecttcpx-dev:v3.1.6_2023_10_06 install --install-nccl

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
    --env LD_LIBRARY_PATH=/usr/local/nvidia/lib64:/usr/lib/lib32:/usr/lib/x86_64-linux-gnu/ \
    --entrypoint /tcpgpudmarxd/build/app/tcpgpudmarxd \
    us-docker.pkg.dev/gce-ai-infra/gpudirect-tcpx/tcpgpudmarxd-dev:v2.0.7 \
    --setup_param "--verbose 128 2 0" \
    --gpu_nic_preset manual \
    --gpu_nic_topology ${GPU_NIC_TOPOLOGY} \
    --gpu_shmem_type fd \
    --uds_path ${UDS_PATH}

sleep 5s

########################################
######### Application Specific #########
DIR=`pwd`
mkdir -p $DIR/logs

srun --ntasks-per-node=1 \
        --container-name="ddp" \
        --container-image="dockerd://nvcr.io/nvidia/pytorch:23.09-py3" \
        --container-mounts="/home:/home,/var/lib/tcpx/lib64:/var/lib/tcpx/lib64,${UDS_PATH}:${UDS_PATH}" \
        --container-workdir=$PWD \
        --container-writable \
        --output=$DIR/logs/%x_%j_$DATETIME.log \
        bash ddp.sh

########################################
########################################

srun --ntasks-per-node=1 docker container stop receive-datapath-manager-${SLURM_JOB_ID}