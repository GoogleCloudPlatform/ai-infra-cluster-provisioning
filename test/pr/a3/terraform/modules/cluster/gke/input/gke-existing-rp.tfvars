region = "us-east4"
node_pools = [{
  zone       = "us-east4-a"
  node_count = 17
  compact_placement_policy = {
    existing_policy_name = "test-rp"
  }
}]
