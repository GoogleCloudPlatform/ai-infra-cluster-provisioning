variable "node_pools" {}
variable "project_id" {}
variable "resource_prefix" {}

module "a3-gke" {
  source = "github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning//terraform/modules/cluster/gke"

  node_pools      = var.node_pools
  project_id      = var.project_id
  resource_prefix = var.resource_prefix
}
