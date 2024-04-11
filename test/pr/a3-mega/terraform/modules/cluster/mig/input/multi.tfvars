instance_groups = [
  {
    target_size = 1
    zone        = "us-central1-a"
  },
  {
    target_size  = 1
    zone         = "us-central1-a"
    machine_type = "a3-megagpu-8g"
  },
]
region                       = "us-central1"
use_compact_placement_policy = true
