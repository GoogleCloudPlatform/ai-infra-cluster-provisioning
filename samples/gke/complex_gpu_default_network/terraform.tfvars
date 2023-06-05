project_id      = "project-id"
resource_prefix = "complex-gke"
region          = "us-central1"
network_config  = "default"
gke_version     = "1.26.4-gke.500"
disk_type       = "pd-ssd"
disk_size_gb    = 200
node_pools = [{
  zone         = "us-central1-a"
  node_count   = 1
  machine_type = "a2-highgpu-1g"
  guest_accelerator = {
    type  = "nvidia-tesla-a100"
    count = 1
  }
  enable_compact_placement = false
}]
kubernetes_setup_config = {
  enable_kubernetes_setup              = true
  kubernetes_service_account_name      = "testksa"
  kubernetes_service_account_namespace = "default"
}