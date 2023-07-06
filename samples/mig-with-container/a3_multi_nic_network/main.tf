variable "project_id" {}
variable "resource_prefix" {}
variable "target_size" {}
variable "zone" {}

variable "machine_type" {}
variable "network_config" {}
variable "startup_script" {}
variable "wait_for_instance" {}

module "a3-mig" {
  source = "github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning//terraform/modules/cluster/mig-with-container"

  project_id      = var.project_id
  resource_prefix = var.resource_prefix
  target_size     = var.target_size
  zone            = var.zone

  machine_type      = var.machine_type
  network_config    = var.network_config
  startup_script    = var.startup_script
  wait_for_instance = var.wait_for_instance
}
