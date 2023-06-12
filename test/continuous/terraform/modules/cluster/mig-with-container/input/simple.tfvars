target_size  = 1
zone         = "us-central1-a"
machine_type = "n2-standard-2"
container = {
  image = "debian"
  cmd   = "sleep infinity"
  env   = { some_key = "some_value" }
}
