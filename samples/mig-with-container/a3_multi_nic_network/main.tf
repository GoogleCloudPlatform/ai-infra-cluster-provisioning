variable "project_id" {}
variable "resource_prefix" {}
variable "target_size" {}
variable "zone" {}

variable "container" {}
variable "disk_size_gb" {}
variable "disk_type" {}
variable "filestore_new" {}
variable "gcsfuse_existing" {}
variable "labels" {}
variable "machine_type" {}
variable "network_config" {}

module "a3-mig" {
  source = "github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning//terraform/modules/cluster/mig-with-container"

  project_id      = var.project_id
  resource_prefix = var.resource_prefix
  target_size     = var.target_size
  zone            = var.zone

  container        = var.container
  disk_size_gb     = var.disk_size_gb
  disk_type        = var.disk_type
  filestore_new    = var.filestore_new
  gcsfuse_existing = var.gcsfuse_existing
  labels           = var.labels
  machine_type     = var.machine_type
  network_config   = var.network_config
}
