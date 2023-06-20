region = "us-central1"
node_pools = [{
  zone                     = "us-central1-f"
  node_count               = 1
  machine_type             = "n1-standard-1"
  guest_accelerator        = null
  enable_compact_placement = false
}]
