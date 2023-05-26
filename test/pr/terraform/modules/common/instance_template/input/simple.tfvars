disk_size_gb = 50
disk_type    = "pd-standard"
guest_accelerator = {
  type  = "nvidia-tesla-v100"
  count = 1
}
labels = {}
machine_image = {
  project = "ubuntu-os-cloud"
  family  = "ubuntu-2204-lts"
  name    = null
}
machine_type = "n1-standard-8"
metadata = {
  foo = "bar"
}
region = "us-central1"
service_account = {
  email  = "foo@bar.xyz"
  scopes = ["foobar"]
}
startup_script        = "echo hello world"
subnetwork_self_links = ["subnetwork_self_link"]
network_self_links    = ["network_self_link"]
