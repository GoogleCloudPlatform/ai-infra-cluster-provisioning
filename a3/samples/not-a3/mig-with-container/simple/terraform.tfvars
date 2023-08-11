project_id      = "project-id"
resource_prefix = "mig-cos"
zone            = "us-central1-a"
target_size     = 1

container = {
  image = "gcr.io/deeplearning-platform-release/base-gpu.py310"
  cmd   = "sleep infinity"
  run_options = {
    env                  = { some_key = "some_value" }
    custom               = ["--shm-size=250g"]
    enable_cloud_logging = true
  }
}
enable_ops_agent = false
filestore_new = [{
  filestore_tier = "BASIC_HDD"
  local_mount    = "/usr/fsmount"
  size_gb        = 1024
}]
gcsfuse_existing = [{
  local_mount  = "/usr/gcsmount"
  remote_mount = "bucketName-To-Mount"
}]
machine_type = "a2-highgpu-1g"
labels       = { purpose = "testing", }
