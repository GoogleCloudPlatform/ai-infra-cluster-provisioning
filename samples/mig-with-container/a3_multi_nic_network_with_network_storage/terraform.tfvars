project_id      = "my-project-id"
resource_prefix = "my-cluster-name"
target_size     = 4
zone            = "us-central1-c"

container = {
  cmd         = null
  image       = "gcr.io/deeplearning-platform-release/base-gpu.py310"
  run_at_boot = true
  run_options = null
}
disk_size_gb = 1024
disk_type    = "pd-ssd"
filestore_new = [
  {
    filestore_tier = "BASIC_HDD"
    local_mount    = "/mnt/nfsmount"
    size_gb        = 1024
  },
]
gcsfuse_existing = [
  {
    local_mount  = "/mnt/gcsmount"
    remote_mount = "my-bucket"
  },
]
labels            = { purpose = "testing" }
machine_type      = "a3-highgpu-8g"
network_config    = "new_multi_nic"
startup_script    = <<-EOT
  #!/bin/sh -e
  docker-credential-gcr configure-docker
  docker-credential-gcr configure-docker --registries us-docker.pkg.dev

  # Configure the Receive Data Path Manager
  docker run --pull=always --rm \
    --name receive-datapath-manager \
    --detach \
    --cap-add=NET_ADMIN --network=host \
    --volume /var/lib/nvidia/lib64:/usr/local/nvidia/lib64 \
    --device /dev/nvidia0:/dev/nvidia0 \
    --device /dev/nvidia1:/dev/nvidia1 \
    --device /dev/nvidia2:/dev/nvidia2 \
    --device /dev/nvidia3:/dev/nvidia3 \
    --device /dev/nvidia4:/dev/nvidia4 \
    --device /dev/nvidia5:/dev/nvidia5 \
    --device /dev/nvidia6:/dev/nvidia6 \
    --device /dev/nvidia7:/dev/nvidia7 \
    --device /dev/nvidia-uvm:/dev/nvidia-uvm \
    --device /dev/nvidiactl:/dev/nvidiactl \
    --env LD_LIBRARY_PATH=/usr/local/nvidia/lib64 \
    --volume /run/tcpx:/run/tcpx \
    --entrypoint /tcpgpudmarxd/build/app/tcpgpudmarxd \
    us-docker.pkg.dev/gce-ai-infra/gpudirect-tcpx/tcpgpudmarxd \
    --gpu_nic_preset a3vm --gpu_shmem_type fd --uds_path "/run/tcpx"

  # Configure NCCL and GPUDirectTCPX plugin
  docker run --rm \
    --volume /var/lib:/var/lib \
    us-docker.pkg.dev/gce-ai-infra/gpudirect-tcpx/nccl-plugin-gpudirecttcpx \
    install --install-nccl
  mount --bind /var/lib/tcpx /var/lib/tcpx
  mount -o remount,exec /var/lib/tcpx
  EOT
wait_for_instance = false
