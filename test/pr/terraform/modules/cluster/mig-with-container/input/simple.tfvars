target_size = 1
zone        = "us-central1-a"
container = {
  image = "debian"
  cmd   = "sleep infinity"
  run_options = {
    custom               = ["--shm-size=250g"]
    enable_cloud_logging = true
    env                  = { some_key = "some_value" }
  }
}
