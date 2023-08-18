compute_partitions = [{
  node_count_dynamic_max = 1
  node_count_static      = 0
  partition_name         = "compute"
  zone                   = "us-east4-a"

  disk_size_gb        = null
  disk_type           = null
  machine_image       = null
  startup_script      = null
  startup_script_file = null
}]
enable_cleanup_compute = true
