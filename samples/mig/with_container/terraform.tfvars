project_id       = "project-id"
resource_prefix  = "complex-mig1"
zone             = "us-central1-a"
machine_type     = "a2-standard-1g"
target_size      = 1
enable_ops_agent = true
filestore_new = [{
  filestore_tier = "BASIC_HDD"
  local_mount    = "/usr/fsmount"
  size_gb        = 1024
}]
gcsfuse_existing = [{
  local_mount  = "/usr/gcsmount"
  remote_mount = "bucketName-To-Mount"
}]
labels = { purpose = "testing", }
container = {
  image = "gcr.io/deeplearning-platform-release/base-gpu.py310"
  cmd   = "sleep infinity"
}
