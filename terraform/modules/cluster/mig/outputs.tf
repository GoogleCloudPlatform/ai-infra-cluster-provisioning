/**
  * Copyright 2022 Google LLC
  *
  * Licensed under the Apache License, Version 2.0 (the "License");
  * you may not use this file except in compliance with the License.
  * You may obtain a copy of the License at
  *
  *      http://www.apache.org/licenses/LICENSE-2.0
  *
  * Unless required by applicable law or agreed to in writing, software
  * distributed under the License is distributed on an "AS IS" BASIS,
  * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  * See the License for the specific language governing permissions and
  * limitations under the License.
  */

output "project_id" { value = var.project_id }
output "resource_prefix" { value = var.resource_prefix }
output "target_size" { value = var.target_size }
output "zone" { value = var.zone }
output "disk_size_gb" { value = var.disk_size_gb }
output "disk_type" { value = var.disk_type }
output "filestore_new" { value = var.filestore_new }
output "gcsfuse_existing" { value = var.gcsfuse_existing }
output "guest_accelerator" { value = var.guest_accelerator }
output "enable_ops_agent" { value = var.enable_ops_agent }
output "enable_ray" { value = var.enable_ray }
output "machine_image" { value = var.machine_image }
output "machine_type" { value = var.machine_type }
output "network_config" { value = var.network_config }
output "service_account" { value = var.service_account }
output "startup_script" { value = var.startup_script }
output "startup_script_file" { value = var.startup_script_file }

output "instructions" {
  description = "Instructions for accessing the dashboard"
  value       = try(module.dashboard[0].instructions, "Dashboard not created")
}
