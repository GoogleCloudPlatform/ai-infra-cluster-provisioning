target_size = 1
zone        = "us-central1-a"
container = {
  image                = "debian"
  cmd                  = "sleep infinity"
  env                  = { some_key = "some_value" }
  options              = ["--shm-size=250g"]
  enable_cloud_logging = true
}
