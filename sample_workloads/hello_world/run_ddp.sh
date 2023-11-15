#!/bin/bash
#
#SBATCH --partition=a3
#SBATCH --exclusive
#SBATCH --gpus-per-node 8
#SBATCH --nodes 1

UDS_PATH="/run/tcpx-${SLURM_JOB_ID}"
GPU_NIC_TOPOLOGY=/opt/tcpdirect_benchmark/gpu_rxq_configuration.textproto
GPU_NIC_TOPOLOGY_DIR=`dirname ${GPU_NIC_TOPOLOGY}`

export MASTER_PORT=12340
export WORLD_SIZE=1

### get the first node name as master address - customized for vgg slurm
### e.g. master(gnodee[2-5],gnoded1) == gnodee2
echo "NODELIST="${SLURM_NODELIST}
master_addr=$(scontrol show hostnames "$SLURM_JOB_NODELIST" | head -n 1)
export MASTER_ADDR=$master_addr
echo "MASTER_ADDR="$MASTER_ADDR

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
    --env LD_LIBRARY_PATH=/usr/local/nvidia/lib64:${UDS_PATH}:/usr/lib/lib32:/usr/lib/x86_64-linux-gnu/ \
    --entrypoint /tcpgpudmarxd/build/app/tcpgpudmarxd \
    us-docker.pkg.dev/gce-ai-infra/gpudirect-tcpx/tcpgpudmarxd-dev:v2.0.7 \
    --setup_param "--verbose 128 2 0" \
    --gpu_nic_preset manual \
    --gpu_nic_topology ${GPU_NIC_TOPOLOGY} \
    --gpu_shmem_type fd \
    --uds_path ${UDS_PATH}

mkdir -p /mnt/localssd/$(id -u)/enroot/config
sbcast -f -p ${HOME}/enroot/.credentials /mnt/localssd/$(id -u)/enroot/config/.credentials
sleep 5s

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
export NCCL_GPUDIRECTTCPX_UNIX_CLIENT_PREFIX=/run/tcpx-${SLURM_JOB_ID}
export NCCL_GPUDIRECTTCPX_PROGRAM_FLOW_STEERING_WAIT_MICROS=1000000
export NCCL_GPUDIRECTTCPX_FORCE_ACK=0
export NCCL_GPUDIRECTTCPX_TX_COMPLETION_NANOSLEEP=1000
export NCCL_GPUDIRECTTCPX_TX_BINDINGS="enp6s0:8-21,112-125;enp12s0:8-21,112-125;enp134s0:60-73,164-177;enp140s0:60-73,164-177"
export NCCL_GPUDIRECTTCPX_RX_BINDINGS="enp6s0:22-35,124-139;enp12s0:22-35,124-139;enp134s0:74-87,178-191;enp140s0:74-87,178-191"

srun --ntasks-per-node=1 \
        --container-mounts="/home:/home" \
        --container-image="docker://$oauthtoken@nvcr.io#nvidia/pytorch:23.05-py3" \
        python sample.py


srun --ntasks-per-node=1 docker container stop receive-datapath-manager-${SLURM_JOB_ID}

