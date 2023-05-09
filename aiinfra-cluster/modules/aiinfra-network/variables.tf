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

variable "project_id" {
  description = "Project in which the HPC deployment will be created"
  type        = string
}

variable "region" {
  description = "Region in which the HPC deployment will be created"
  type        = string
}

variable "resource_prefix" {
  description = "Name of the deployment, used to name the cluster"
  type        = string
}

variable "nic_count" {
  description = "The NIC count"
  type        = number
  default     = 5
}

variable "network_config" {
  description = "The network configuration to specify the type of VPC to be used"
  type        = string
  default     = "default_network"

  validation {
    condition     = contains(["default_network", "new_network", "multi_nic_network"], var.network_config)
    error_message = "Variable network_config must be one of default_network, new_network, or multi_nic_network."
  }
}
