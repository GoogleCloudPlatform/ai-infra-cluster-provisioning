project_id      = "my-project-id"
resource_prefix = "my-cluster-name"
target_size     = 4
zone            = "us-central1-c"

container = {
  cmd         = null
  image       = "gcr.io/deeplearning-platform-release/base-gpu.py310"
  run_at_boot = true
  run_options = null
}
disk_size_gb = 1024
disk_type    = "pd-ssd"
filestore_new = [
  {
    filestore_tier = "BASIC_HDD"
    local_mount    = "/mnt/nfsmount"
    size_gb        = 1024
  },
]
gcsfuse_existing = [
  {
    local_mount  = "/mnt/gcsmount"
    remote_mount = "my-bucket"
  },
]
labels         = { purpose = "testing" }
machine_type   = "a3-highgpu-8g"
network_config = "new_multi_nic"
