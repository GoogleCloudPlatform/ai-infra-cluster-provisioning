instance_groups = [
  {
    target_size = 4
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
region = "us-east4"

use_compact_placement_policy = true
container = {
  image       = "debian"
  cmd         = "sleep infinity"
  run_at_boot = true
  run_options = {
    custom               = ["--shm-size=250g"]
    enable_cloud_logging = true
    env                  = { some_key = "some_value" }
  }
}
