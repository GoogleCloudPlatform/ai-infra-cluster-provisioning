variable "node_pools" {}
variable "project_id" {}
variable "resource_prefix" {}
variable "region" {}

module "a3-mega-gke" {
  source = "github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning//a3-mega/terraform/modules/cluster/gke"

  node_pools      = var.node_pools
  project_id      = var.project_id
  resource_prefix = var.resource_prefix
  region          = var.region
}
