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
  description = <<-EOT
    The ID of the project in which the resource belongs.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_resource_policy#project).
    EOT
  type        = string
}

variable "resource_prefix" {
  description = "Arbitrary string with which all names of newly created resources will be prefixed."
  type        = string

  validation {
    condition     = var.resource_prefix != null
    error_message = "must not be null"
  }
}

variable "region" {
  description = <<-EOT
    The region in which the resource policy(s) has been / will be created.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_resource_policy#region).
    EOT
  type        = string
}

variable "policy_count" {
  description = "The number of resource policy(s) that needs to be created"
  type        = number
  default     = 1

  validation {
    condition     = var.policy_count != null
    error_message = "must not be null"
  }
}

variable "availability_domain_count" {
  description = <<-EOT
    The number of availability domains instances will be spread across. If two instances are in different availability domain, they will not be put in the same low latency network

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_resource_policy#availability_domain_count).
    EOT
  type        = number
  default     = 1
}
