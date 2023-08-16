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

variable "enable_auto_config_apply" {
  description = <<-EOT
    Whenever you update a MIG's instance_template, Compute Engine automatically applies your updated configuration to new VMs that are added to the group.
    This flag enables automatic application of an updated configuration to existing VMs.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_group_manager#nested_update_policy), [doc](https://cloud.google.com/compute/docs/instance-groups/rolling-out-updates-to-managed-instance-groups) 
    EOT
  type        = bool
  default     = true

  validation {
    condition     = var.enable_auto_config_apply != null
    error_message = "must not be null"
  }
}

variable "instance_template_id" {
  description = <<-EOT
    The full URL to an instance template from which all new instances of this version will be created.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_instance_group_manager#instance_template).
    EOT
  type        = string
}

variable "project_id" {
  description = <<-EOT
    The ID of the project in which the resource belongs.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#project).
    EOT
  type        = string

  validation {
    condition     = var.project_id != null
    error_message = "must not be null"
  }
}

variable "resource_prefix" {
  description = "Arbitrary string with which all names of newly created resources will be prefixed."
  type        = string

  validation {
    condition     = var.resource_prefix != null
    error_message = "must not be null"
  }
}

variable "target_size" {
  description = <<-EOT
    The number of running instances for this managed instance group.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_group_manager#target_size), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-groups/managed/create#--size).
    EOT
  type        = number

  validation {
    condition     = var.target_size != null
    error_message = "must not be null"
  }
}

variable "wait_for_instances" {
  description = <<-EOT
    Whether to wait for all instances to be created/updated before returning. Note that if this is set to true and the operation does not succeed, Terraform will continue trying until it times out.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_instance_group_manager#wait_for_instances). 
    EOT
  type        = bool
  default     = true

  validation {
    condition     = var.wait_for_instances != null
    error_message = "must not be null"
  }
}

variable "zone" {
  description = <<-EOT
    The zone that instances in this group should be created in.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_group_manager#zone), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-groups/managed/create#--zone).
    EOT
  type        = string
}
