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

output "disk_size_gb" { value = var.disk_size_gb }
output "disk_type" { value = var.disk_type }
output "guest_accelerator" { value = var.guest_accelerator }
output "machine_type" { value = var.machine_type }
output "project_id" { value = var.project_id }
output "region" { value = var.region }
output "resource_prefix" { value = var.resource_prefix }
output "startup_script" { value = var.startup_script }
output "subnetwork_self_links" { value = var.subnetwork_self_links }

output "machine_image" { value = local.machine_image }
output "metadata" { value = local.metadata }
output "service_account" { value = local.service_account }

output "id" {
  description = "`id` output of the google_compute_instance_template resource created."
  value       = resource.google_compute_instance_template.template.id
}

output "name" {
  description = "`name` output of the google_compute_instance_template resource created."
  value       = resource.google_compute_instance_template.template.name
}

output "self_link" {
  description = "`self_link` output of the google_compute_instance_template resource created"
  value       = resource.google_compute_instance_template.template.self_link
}
