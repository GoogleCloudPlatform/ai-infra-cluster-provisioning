project_id      = "gce-ai-infra"
resource_prefix = "ci"
region          = "us-central1"
node_pools = [{
  zone                     = "us-central1-a"
  node_count               = 1
  machine_type             = "n1-standard-1"
  guest_accelerator_type   = ""
  guest_accelerator_count  = 0
  enable_compact_placement = false
}]
