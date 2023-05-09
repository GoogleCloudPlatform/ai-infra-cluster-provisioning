module "production" {
  source = "../common"

  region = "us-central1"
  zone = "us-central1-a"
  deployment_name = "prod-a3"
  num_migs = 2
  num_machines_per_mig = 2
  os_image = "debian-11"
}
