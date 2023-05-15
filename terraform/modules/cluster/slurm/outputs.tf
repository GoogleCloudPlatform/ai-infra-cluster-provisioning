output "project_id" { value = var.project_id }
output "resource_prefix" { value = var.resource_prefix }
output "filestore_new" { value = var.filestore_new }
output "gcsfuse_existing" { value = var.gcsfuse_existing }
output "network_config" { value = var.network_config }
output "service_account" { value = var.service_account }

output "compute_partitions" {
  value = [
    for name in local.partition_names
    : local.compute_partitions[name]
  ]
}

output "controller_var" { value = local.controller_var }

output "login_var" { value = local.login_var }
