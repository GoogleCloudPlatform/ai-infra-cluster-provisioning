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
  description = "ID of the network"
  value = flatten([
    module.default_vpc[*].network_id,
    resource.google_compute_network.networks[*].id,
  ])[0]
}

output "network_self_links" {
  description = "Network self-links of all the VPCs"
  value = flatten([
    module.default_vpc[*].network_self_link,
    resource.google_compute_network.networks[*].self_link,
  ])
}

output "network_names" {
  description = "Network names of all the VPCs"
  value = flatten([
    module.default_vpc[*].network_name,
    resource.google_compute_network.networks[*].name,
  ])
}

output "subnetwork_self_links" {
  description = "Subnet self-links of all the VPCs"
  value = flatten([
    module.default_vpc[*].subnetwork_self_link,
    resource.google_compute_subnetwork.subnets[*].self_link,
  ])
}

output "subnetwork_names" {
  description = "Subnet names of all the VPCs"
  value = flatten([
    module.default_vpc[*].subnetwork_name,
    resource.google_compute_subnetwork.subnets[*].name,
  ])
}
