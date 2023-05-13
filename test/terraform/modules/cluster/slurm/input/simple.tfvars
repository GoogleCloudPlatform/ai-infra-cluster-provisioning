project_id      = "gce-ai-infra"
resource_prefix = "ci"
compute_partitions = [{
  node_count_static = 1
  partition_name    = "compute"
  zone              = "us-central1-a"
}]
