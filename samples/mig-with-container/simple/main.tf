variable "project_id" {}
variable "resource_prefix" {}
variable "target_size" {}
variable "zone" {}

variable "container" {}
variable "enable_ops_agent" {}
variable "filestore_new" {}
variable "gcsfuse_existing" {}
variable "labels" {}
variable "machine_type" {}

module "mig-with-container" {
  source = "github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning//terraform/modules/cluster/mig-with-container"

  project_id      = var.project_id
  resource_prefix = var.resource_prefix
  target_size     = var.target_size
  zone            = var.zone

  container        = var.container
  enable_ops_agent = var.enable_ops_agent
  filestore_new    = var.filestore_new
  gcsfuse_existing = var.gcsfuse_existing
  labels           = var.labels
  machine_type     = var.machine_type
}
