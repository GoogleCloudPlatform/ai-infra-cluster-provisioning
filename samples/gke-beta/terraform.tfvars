project_id      = "project-id"
resource_prefix = "a3-multi-nic"
region          = "us-east4"
gke_version     = "1.26.5-gke.2100"
disk_size_gb    = 1000
disk_type       = "pd-ssd"
node_pools = [{
  zone                     = "us-east4-a"
  node_count               = 1
  machine_type             = "a3-highgpu-8g"
  enable_compact_placement = true
}]
kubernetes_setup_config = {
  kubernetes_service_account_name      = "test-ksa"
  kubernetes_service_account_namespace = "default"
}