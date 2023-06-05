project_id      = "project-id"
resource_prefix = "a3-mig"
zone            = "us-central1-c"
network_config  = "new_multi_nic"
machine_type    = "a3-highgpu-8g"
target_size     = 1
enable_ray      = true
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
machine_image = {
  family  = "pytorch-latest-gpu-debian-11-py310",
  name    = null,
  project = "deeplearning-platform-release"
}
startup_script = "echo \"Hello World\""
