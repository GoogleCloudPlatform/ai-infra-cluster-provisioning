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

variable "network_self_link" {
  description = "Self link of network to which the cluster will be attached"
  type        = string
}

variable "subnetwork_address" {
  description = "Address range of subnetwork to which the cluster will be attached"
  type        = string
}

variable "subnetwork_self_link" {
  description = "Self link of subnetwork to which the cluster will be attached"
  type        = string
}

## Filestore

variable "network_storage" {
  description = "Storage to mount on all instances"
  type = list(string)
  default = []
}

variable "labels" {
  description = "Labels to add to the instances. List key, value pairs."
  type        = map
  default     = {}
}


## Node Group

variable "node_count_static" {
  description = "Number of statically allocated nodes in compute partition"
  type        = number
}

variable "node_count_dynamic_max" {
  description = "Maximum number of dynamically allocated nodes allowed in compute partition"
  type        = number
}

variable "instance_template_compute" {
  description = "Self link to the instance template to be used for creating compute nodes."
  type        = string
}

variable "instance_template_controller" {
  description = "Self link to the instance template to be used for creating controller node."
  type        = string
}

variable "instance_template_login" {
  description = "Self link to the instance template to be used for creating login node."
  type        = string
}

## Controller

variable "service_account" {
  description = "Service account to attach to the instance. See https://www.terraform.io/docs/providers/google/r/compute_instance_template.html#service_account."
  type = object({
    email  = string,
    scopes = set(string)
  })
}
