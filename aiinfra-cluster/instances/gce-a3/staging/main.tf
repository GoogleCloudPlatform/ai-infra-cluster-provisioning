module "staging" {
  source = "../common"

  region = "us-central1"
  zone = "us-central1-staginga"
  deployment_name = "staging-a3-do-not-delete"
  num_migs = 2
  num_machines_per_mig = 2
  os_image = "gce-staging-images/debian-11"
}
