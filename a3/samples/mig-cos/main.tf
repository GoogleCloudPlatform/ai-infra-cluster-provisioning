variable "project_id" {}
variable "resource_prefix" {}
variable "target_size" {}
variable "zone" {}

module "a3-mig-cos" {
  source = "github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning//terraform/modules/cluster/mig-cos"

  project_id      = var.project_id
  resource_prefix = var.resource_prefix
  target_size     = var.target_size
  zone            = var.zone
}
