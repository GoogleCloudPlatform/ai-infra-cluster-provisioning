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
  nullable    = false
}

variable "new_resource_policy_name" {
  description = <<-EOT
    The name of the new resource policy to be created. 

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_resource_policy#name).
    EOT
  type        = string
}

variable "existing_resource_policy_name" {
  description = <<-EOT
    The name of the existing resource policy. 

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_resource_policy#name).
    EOT
  type        = string
  default     = null
}

variable "region" {
  description = <<-EOT
    The region in which the resource policy(s) has been / will be created.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_resource_policy#region).
    EOT
  type        = string
  nullable    = false
}
