region = "us-east4"
node_pools = [{
  zone                          = "us-east4-a"
  node_count                    = 17
  use_compact_placement_policy  = true
  existing_resource_policy_name = "test-rp"
}]
