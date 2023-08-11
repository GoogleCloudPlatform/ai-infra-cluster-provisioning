project_id      = "project-id"
resource_prefix = "simple-gke"
region          = "us-central1"
node_pools = [{
  zone         = "us-central1-a"
  node_count   = 1
  machine_type = "n1-standard-1"
}]