target_size  = 1
zone         = "us-central1-a"
machine_type = "a2-highgpu-1g"
guest_accelerator = {
  count = 1
  type  = "nvidia-tesla-a100"
}
