target_size = 1
zone        = "us-central1-a"

disk_size_gb = 50
disk_type    = "pd-standard"
labels       = {}
machine_image = {
  project = "ubuntu-os-cloud"
  family  = "ubuntu-2204-lts"
  name    = null
}
machine_type         = "n1-standard-8"
maintenance_interval = null
metadata = {
  foo = "bar"
}
network_self_link    = "network_self_link"
subnetwork_self_link = "subnetwork_self_link"
region               = "us-central1"
service_account = {
  email  = "foo@bar.xyz"
  scopes = ["foobar"]
}
startup_script               = "echo hello world"
subnetwork_self_links        = ["subnetwork_self_link"]
use_compact_placement_policy = true
