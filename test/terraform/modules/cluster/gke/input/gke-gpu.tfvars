project_id      = "gce-ai-infra"
resource_prefix = "ci"
region          = "us-central1"
node_pools = [{
  zone                     = "us-central1-a"
  node_count               = 1
  machine_type             = "a2-highgpu-1g"
  guest_accelerator_type   = "nvidia-tesla-a100"
  guest_accelerator_count  = 1
  enable_compact_placement = false
}]
