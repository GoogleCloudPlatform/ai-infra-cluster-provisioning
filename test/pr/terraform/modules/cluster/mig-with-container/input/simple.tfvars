target_size = 1
zone        = "us-central1-a"
container = {
  image = "debian"
  cmd   = "sleep infinity"
  env   = { some_key = "some_value" }
}
