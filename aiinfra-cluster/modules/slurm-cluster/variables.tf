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
  description = "Name of the project to use for instantiating clusters."
  type        = string
}

variable "deployment_name" {
  description = "The deployment name. Default value is name_prefix-depl."
  type        = string
  default     = null
}

variable "zone" {
  description = "GCP zone where to create resources. Only use if multi_zonal is false."
  type        = string
}

variable "region" {
  description = "GCP region where to create resources."
  type        = string
}

variable "network_name" {
  description = "Name of the network in which the filestore and cluster will be created."
  type        = string
}

variable "subnetwork_self_link" {
  description = "The self link of the subnetwork to attach the VM."
  type        = string
}

## Filestore

#variable "filestore_size_gb" {
#  description = "Storage size of the filestore instance in GB."
#  type        = number
#}
#
#variable "filestore_tier" {
#  description = "Service tier of the filestore instance."
#  type        = number
#}

variable "labels" {
  description = "Labels to add to the filestore instance."
  type        = map(string)
  default     = {}
}

## Node Group

#variable "node_count_dynamic_max" {
#  description = "Maximum number of dynamic nodes allowed in this partition"
#  type        = number
#}
#
#variable "instance_template" {
#  description = "Self link to the instance template to be used for creating compute and controller nodes."
#  type        = string
#}

## Controller

variable "service_account" {
  description = "Service account to attach to the instance. See https://www.terraform.io/docs/providers/google/r/compute_instance_template.html#service_account."
  type = object({
    email  = string,
    scopes = set(string)
  })
}