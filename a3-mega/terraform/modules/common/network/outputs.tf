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

output "network_ids" {
  description = "Network ids of all the VPCs"
  value = concat(
    [local.nic0.network.id],
    resource.google_compute_network.gpus[*].id,
  )
}

output "network_self_links" {
  description = "Network self-links of all the VPCs"
  value = concat(
    [local.nic0.network.self_link],
    resource.google_compute_network.gpus[*].self_link,
  )
}

output "network_names" {
  description = "Network names of all the VPCs"
  value = concat(
    [local.nic0.network.name],
    resource.google_compute_network.gpus[*].name,
  )
}

output "subnetwork_self_links" {
  description = "Subnet self-links of all the VPCs"
  value = concat(
    [local.nic0.subnetwork.self_link],
    resource.google_compute_subnetwork.gpus[*].self_link,
  )
}

output "subnetwork_names" {
  description = "Subnet names of all the VPCs"
  value = concat(
    [local.nic0.subnetwork.name],
    resource.google_compute_subnetwork.gpus[*].name,
  )
}
