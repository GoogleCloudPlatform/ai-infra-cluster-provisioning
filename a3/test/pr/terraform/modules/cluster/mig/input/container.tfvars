target_size = 1
zone        = "us-central1-a"

machine_type = "n1-standard-8"
guest_accelerator = {
  count = 1
  type  = "nvidia-tesla-t4"
}
container = {
  image = "gcr.io/deeplearning-platform-release/base-gpu.py310"
  cmd   = "sleep 300"
}
filestore_new = [
  {
    filestore_tier = "BASIC_HDD"
    local_mount    = "/mnt/input"
    size_gb        = 1024
  },
  {
    filestore_tier = "BASIC_HDD"
    local_mount    = "/mnt/output"
    size_gb        = 1024
  },
]
