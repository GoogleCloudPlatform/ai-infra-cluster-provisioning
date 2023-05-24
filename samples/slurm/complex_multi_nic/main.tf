variable "compute_partitions" {}
variable "project_id" {}
variable "resource_prefix" {}

variable "controller_var" {}
variable "filestore_new" {}
variable "gcsfuse_existing" {}
variable "labels" {}
variable "login_var" {}
variable "network_config" {}
variable "service_account" {}
variable "startup_script_gcs_bucket_path" {}

module "cluster" {
  source = "github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning//terraform/modules/cluster/slurm?ref=rework"

  compute_partitions = var.compute_partitions
  project_id         = var.project_id
  resource_prefix    = var.resource_prefix

  controller_var                 = var.controller_var
  filestore_new                  = var.filestore_new
  gcsfuse_existing               = var.gcsfuse_existing
  labels                         = var.labels
  login_var                      = var.login_var
  network_config                 = var.network_config
  service_account                = var.service_account
  startup_script_gcs_bucket_path = var.startup_script_gcs_bucket_path
}
