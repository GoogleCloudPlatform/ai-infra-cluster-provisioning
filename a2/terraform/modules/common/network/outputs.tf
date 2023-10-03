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

output "network_id" {
  description = "Network id of the host VPC"
  value       = local.nic.network.id
}

output "network_self_link" {
  description = "Network self-link of the host VPC."
  value       = local.nic.network.self_link
}

output "network_name" {
  description = "Network name of the host VPC."
  value       = local.nic.network.name
}

output "subnetwork_self_link" {
  description = "Subnet self-link of the host VPC."
  value       = local.nic.subnetwork.self_link
}

output "subnetwork_name" {
  description = "Subnet name of the host VPC."
  value       = local.nic.subnetwork.name
}
