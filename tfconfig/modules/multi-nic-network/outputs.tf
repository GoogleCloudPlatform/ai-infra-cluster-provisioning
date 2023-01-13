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

output "network1_self_link" {
  description = "The URI of the network1 VPC being created"
  value       = module.network1.network_self_link
  depends_on  = [module.network1]
}

output "subnetwork1_self_link" {
  description = "The self-link to the primary subnetwork of network1 VPC"
  value       = module.network1.subnetwork_self_link
  depends_on  = [module.network1]
}

output "network2_self_link" {
  description = "The URI of the network2 VPC being created"
  value       = module.network2.network_self_link
  depends_on  = [module.network2]
}

output "subnetwork2_self_link" {
  description = "The self-link to the primary subnetwork of network2 VPC"
  value       = module.network2.subnetwork_self_link
  depends_on  = [module.network2]
}

output "network3_self_link" {
  description = "The URI of the network3 VPC being created"
  value       = module.network3.network_self_link
  depends_on  = [module.network3]
}

output "subnetwork3_self_link" {
  description = "The self-link to the primary subnetwork of network3 VPC"
  value       = module.network3.subnetwork_self_link
  depends_on  = [module.network3]
}

output "network4_self_link" {
  description = "The URI of the network4 VPC being created"
  value       = module.network4.network_self_link
  depends_on  = [module.network4]
}

output "subnetwork4_self_link" {
  description = "The self-link to the primary subnetwork of network4 VPC"
  value       = module.network4.subnetwork_self_link
  depends_on  = [module.network4]
}

output "network5_self_link" {
  description = "The URI of the network5 VPC being created"
  value       = module.network5.network_self_link
  depends_on  = [module.network5]
}

output "subnetwork5_self_link" {
  description = "The self-link to the primary subnetwork of network5 VPC"
  value       = module.network5.subnetwork_self_link
  depends_on  = [module.network5]
}

output "multi_network_interface" {
  description = "The network interface that includes all VPC subnets"
  value       = [{
          access_config      = []
          alias_ip_range     = []
          ipv6_access_config = []
          network            = null
          network_ip         = null
          queue_count        = null
          stack_type         = null
          nic_type           = "GVNIC"
          subnetwork         = module.network1.subnetwork_self_link
          subnetwork_project = var.project_id
          }, {
          access_config      = []
          alias_ip_range     = []
          ipv6_access_config = []
          network            = null
          network_ip         = null
          queue_count        = null
          stack_type         = null
          nic_type           = "GVNIC"
          subnetwork         = module.network2.subnetwork_self_link
          subnetwork_project = var.project_id
        }, {
          access_config      = []
          alias_ip_range     = []
          ipv6_access_config = []
          network            = null
          network_ip         = null
          queue_count        = null
          stack_type         = null
          nic_type           = "GVNIC"
          subnetwork         = module.network3.subnetwork_self_link
          subnetwork_project = var.project_id
        }, {
          access_config      = []
          alias_ip_range     = []
          ipv6_access_config = []
          network            = null
          network_ip         = null
          queue_count        = null
          stack_type         = null
          nic_type           = "GVNIC"
          subnetwork         = module.network4.subnetwork_self_link
          subnetwork_project = var.project_id
        }, {
          access_config      = []
          alias_ip_range     = []
          ipv6_access_config = []
          network            = null
          network_ip         = null
          queue_count        = null
          stack_type         = null
          nic_type           = "GVNIC"
          subnetwork         = module.network5.subnetwork_self_link
          subnetwork_project = var.project_id
        }]
  depends_on  = [module.network1, module.network2, module.network3, module.network4, module.network5]
}