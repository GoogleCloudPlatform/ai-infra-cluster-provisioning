instance_groups = [
  {
    target_size = 1
    zone        = "us-central1-a"
  },
  {
    target_size  = 1
    zone         = "us-central1-a"
    machine_type = "a2-highgpu-1g"
  },
]
region                       = "us-central1"
use_compact_placement_policy = true
