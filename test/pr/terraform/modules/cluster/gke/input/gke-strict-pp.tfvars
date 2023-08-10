region         = "us-central1"
network_config = "default_multi_nic"
node_pools = [{
  zone                   = "us-central1-f"
  node_count             = 15
  machine_type           = "a2-highgpu-1g"
  compact_placement_type = "strict"
}]
