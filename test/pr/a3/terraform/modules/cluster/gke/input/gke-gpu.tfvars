region = "us-central1"
network_existing = {
  network_name    = "default"
  subnetwork_name = "default"
}
node_pools = [{
  zone         = "us-central1-f"
  node_count   = 1
  machine_type = "a2-highgpu-1g"
}]
