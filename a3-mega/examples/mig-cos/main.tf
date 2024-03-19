variable "instance_groups" {}
variable "project_id" {}
variable "region" {}
variable "resource_prefix" {}

module "a3-mig-cos" {
  source = "github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning//a3-mega/terraform/modules/cluster/mig-cos"

  instance_groups = var.instance_groups
  project_id      = var.project_id
  region          = var.region
  resource_prefix = var.resource_prefix
}
