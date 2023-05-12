disk_size_gb = 50
disk_type    = "pd-standard"
guest_accelerator = {
  type  = "nvidia-tesla-v100"
  count = 1
}
machine_image = {
  project = "ubuntu-os-cloud"
  family  = "ubuntu-2204-lts"
  name    = null
}
machine_type = "n1-standard-8"
metadata = {
  foo = "bar"
}
project_id      = "gce-ai-infra"
region          = "us-central1"
resource_prefix = "ci"
service_account = {
  email  = "foo@bar.xyz"
  scopes = ["foobar"]
}
startup_script = "echo hello world"
subnetwork_self_links = [
  "https://www.googleapis.com/compute/v1/projects/gce-ai-infra/regions/us-central1/subnetworks/default",
]
