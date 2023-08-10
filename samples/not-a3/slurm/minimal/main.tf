variable "compute_partitions" {}
variable "project_id" {}
variable "resource_prefix" {}

module "cluster" {
  source = "github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning//terraform/modules/cluster/slurm"

  compute_partitions = var.compute_partitions
  project_id         = var.project_id
  resource_prefix    = var.resource_prefix
}
