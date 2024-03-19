instance_groups = [
  {
    target_size = 1
    zone        = "us-east4-a"
  },
  {
    target_size                   = 1
    zone                          = "us-east4-a"
    machine_type                  = "a3-megagpu-8g"
    existing_resource_policy_name = "test-rp"
  },
  {
    target_size                   = 1
    zone                          = "us-east4-a"
    machine_type                  = "a3-megagpu-8g"
    existing_resource_policy_name = "test-rp"
  },
]
region                       = "us-east4"
use_compact_placement_policy = true
