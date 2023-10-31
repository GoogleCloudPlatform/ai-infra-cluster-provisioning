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

output "id" {
  description = "`id` output of the google_compute_instance_template resource created."
  value       = resource.google_compute_instance_template.template.id
}

output "name" {
  description = "`name` output of the google_compute_instance_template resource created."
  value       = var.use_static_naming ? var.resource_prefix : resource.google_compute_instance_template.template.name
}

output "self_link" {
  description = "`self_link` output of the google_compute_instance_template resource created"
  value       = resource.google_compute_instance_template.template.self_link
}

output "service_account" { value = local.service_account }
