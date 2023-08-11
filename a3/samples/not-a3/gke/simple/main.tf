variable "project_id" {}
variable "resource_prefix" {}
variable "region" {}
variable "node_pools" {}
module "simple-gke" {
  source          = "github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning//terraform/modules/cluster/gke"
  project_id      = var.project_id
  resource_prefix = var.resource_prefix
  region          = var.region
  node_pools      = var.node_pools
}