target_size  = 1
zone         = "us-central1-f"
machine_type = "n2-standard-2"
container = {
  image       = "debian"
  cmd         = "sleep infinity"
  run_at_boot = true
  run_options = {
    custom               = ["--shm-size=250g"]
    enable_cloud_logging = true
    env                  = { some_key = "some_value" }
  }
}
