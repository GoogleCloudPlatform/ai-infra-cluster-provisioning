project_id = "project"
name_prefix = "test"
deployment_name = "test-dpl"
zone = "us-central1-a"
region = "us-central1"
gpu_per_vm = 2
machine_type = "a2-highgpu-2g"
metadata = {}
accelerator_type = "nvidia-tesla-a100"
instance_image = {
  family = "pytorch-1-12-gpu-debian-10"
  name = ""
  project = "ml-images"
}
labels = { aiinfra-cluster="uuid", }
disk_size_gb = 2000
disk_type = "pd-ssd"
network_config = "default_network"
instance_count = 1
