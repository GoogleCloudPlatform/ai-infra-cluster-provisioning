compute_partitions = [
  {
    node_count_static = 32
    partition_name    = "infer"
    zone              = "us-central1-a"

    disk_size_gb = 256
    disk_type    = "pd-ssd"
    guest_accelerator = {
      count = 4
      type  = "nvidia-tesla-t4"
    }
    machine_image       = null
    machine_type        = "n1-standard-32"
    startup_script      = "sudo apt update && sudo apt upgrade -y"
    startup_script_file = null
  },
  {
    node_count_static = 16
    partition_name    = "train"
    zone              = "us-central1-c"

    disk_size_gb        = 512
    disk_type           = "pd-ssd"
    guest_accelerator   = null
    machine_image       = null
    machine_type        = "a2-highgpu-8g"
    startup_script      = null
    startup_script_file = null
  },
]
project_id      = "myproject"
resource_prefix = "mycluster"

controller_var = {
  zone                = null
  disk_size           = null
  disk_type           = null
  machine_image       = null
  machine_type        = "c2-standard-16"
  startup_script      = null
  startup_script_file = null
}
filestore_new = [
  {
    filestore_tier = "BASIC_SSD"
    local_mount    = "/mnt/nfs"
    size_gb        = 4096
  },
]
gcsfuse_existing = [
  {
    local_mount  = "/mnt/gcs"
    remote_mount = "mybucket"
  },
]
labels = {
  mylabelkey = "mylabelvalue"
}
login_var = {
  zone                = null
  disk_size           = null
  disk_type           = "pd-balanced"
  machine_image       = null
  machine_type        = null
  startup_script      = null
  startup_script_file = null
}
network_config = "new_multi_nic"
service_accout = {
  email  = "someserviceaccount@myproject.iam.gserviceaccount.com"
  scopes = ["cloud-platform"]
}
startup_script_gcs_bucket_path = "gs://mybucket/startupscripts"
