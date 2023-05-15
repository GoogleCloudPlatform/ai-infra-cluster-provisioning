project_id      = "gce-ai-infra"
resource_prefix = "ci"
compute_partitions = [
  {
    node_count_static = 1
    partition_name    = "comp0"
    zone              = "us-central1-a"

    disk_size_gb        = null
    disk_type           = null
    guest_accelerator   = null
    machine_type        = null
    startup_script      = null
    startup_script_file = null
  },
  {
    node_count_static = 1
    partition_name    = "comp1"
    zone              = "us-central1-a"

    disk_size_gb        = null
    disk_type           = null
    guest_accelerator   = null
    machine_type        = null
    startup_script      = null
    startup_script_file = null
  },
]
