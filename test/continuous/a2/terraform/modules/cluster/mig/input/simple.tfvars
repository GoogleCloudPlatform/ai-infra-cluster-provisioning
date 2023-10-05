instance_groups = [
  {
    target_size  = 0
    zone         = "us-central1-a"
    machine_type = "a2-highgpu-8g"
  },
  {
    target_size  = 0
    zone         = "us-central1-a"
    machine_type = "a2-highgpu-1g"
  },
]
region = "us-central1"
