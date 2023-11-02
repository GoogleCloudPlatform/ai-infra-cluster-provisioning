region = "us-east4"
node_pools = [{
  zone       = "us-east4-a"
  node_count = 17
  compact_placement_policy = {
    new_policy = true
  }
}]
