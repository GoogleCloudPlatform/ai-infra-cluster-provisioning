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

output "network_name" {
  description = "The name of the primary network of all the VPCs created."
  value       = local.primary_network.network_name
}

output "subnetwork_self_link" {
  description = "The subnetwork_self_link of the primary network of all the VPCs created."
  value       = local.primary_network.subnetwork_self_link
}

output "network_self_link" {
  description = "The network_self_link of the primary network of all the VPCs created."
  value       = local.primary_network.network_self_link
}

output "network_interfaces" {
  description = "The network interface that includes all VPC subnets."
  value = local.trimmed_net_config == "multi_nic_network" ? [for idx in range(var.nic_count) : {
    access_config      = idx == 0 ? [local.empty_access_config] : []
    alias_ip_range     = []
    ipv6_access_config = []
    network            = null
    network_ip         = null
    queue_count        = null
    stack_type         = null
    nic_type           = "GVNIC"
    subnetwork         = module.multinic_vpc[idx].subnetwork_self_link
    subnetwork_project = var.project_id
    }
  ] : []

  depends_on = [module.multinic_vpc]
}
