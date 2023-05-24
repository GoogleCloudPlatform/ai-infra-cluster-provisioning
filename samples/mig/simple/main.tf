variable "project_id" {}
variable "resource_prefix" {}
variable "target_size" {}
variable "zone" {}
variable "machine_type" {}
module "simple-mig" {
  source          = "github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning//terraform/modules/cluster/mig//?ref=rework"
  project_id      = var.project_id
  resource_prefix = var.resource_prefix
  target_size     = var.target_size
  zone            = var.zone
  machine_type    = var.machine_type
}