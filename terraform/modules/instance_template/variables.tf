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

variable "disk_size_gb" {
  description = "Size of disk for instances."
  type        = number
}

variable "disk_type" {
  description = "Disk type for instances."
  type        = string
}

variable "extra_metadata" {
  description = "Metadata to add to each instance."
  type        = map(string)
}

variable "guest_accelerator" {
  description = "The type and count of accelerator card attached to the instance."
  type = object({
    type  = string,
    count = number
  })
}

variable "machine_image" {
  description = "Instance Image"
  type = object({
    project = string
    family  = string,
    name    = string,
  })

  validation {
    condition = (
      var.machine_image != null
      // project is non-empty
      && alltrue([
        for empty in [null, ""]
        : var.machine_image.project != empty
      ])
      // at least one is non-empty
      && anytrue([
        for value in [var.machine_image.name, var.machine_image.family]
        : alltrue([for empty in [null, ""] : value != empty])
      ])
      // at least one is empty
      && anytrue([
        for value in [var.machine_image.name, var.machine_image.family]
        : anytrue([for empty in [null, ""] : value == empty])
      ])
    )
    error_message = "project must be non-empty exactly one of family or name must be non-empty"
  }
}

variable "machine_type" {
  description = "Machine type to use for the instance creation"
  type        = string
}

variable "project_id" {
  description = "Project in which resources will be created."
  type        = string
}

variable "region" {
  description = "Region in which instances of this template will be created."
  type        = string
}

variable "resource_prefix" {
  description = "Arbitrary string with which all names of newly created resources will be prefixed."
  type        = string
}

variable "service_account" {
  description = "Service account to attach to the instance. Will default to the GCE default service account"
  type = object({
    email  = string,
    scopes = set(string)
  })
}

variable "startup_script" {
  description = "Startup script used on the instance"
  type        = string
}

variable "subnetwork_self_links" {
  description = "Primary subnet self-links for all the VPCs."
  type        = list(string)

  validation {
    condition     = length(var.subnetwork_self_links) != 0
    error_message = "Must have one or more subnetwork self-link"
  }
}
