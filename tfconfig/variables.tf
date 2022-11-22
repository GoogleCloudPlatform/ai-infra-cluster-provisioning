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

variable "name_prefix" {
  description = ""
  type        = string
}

variable "gpu_per_vm" {
  description = ""
  type        = number
}

variable "service_account" {
  description = ""
  type        = string
}

variable "project_id" {
  description = ""
  type        = string
}

variable "instance_count" {
  description = ""
  type        = number
}

variable "zone" {
  description = ""
  type        = string
}

variable "machine_type" {
  description = ""
  type        = string
}

variable "instance_image" {
  description = ""
  type        = map
}

variable "labels" {
  description = ""
  type        = map
}

variable "metadata" {
  description = ""
  type        = map
}

variable "deployment_name" {
  description = ""
  type        = string
}

variable "gcs_path" {
  description = ""
  type        = string
}

variable "gcs_bucket" {
  description = ""
  type        = string
}

variable "region" {
  description = ""
  type        = string
}

variable "accelerator_type" {
  description = ""
  type        = string
}

variable "disk_size_gb" {
  description = ""
  type        = number
}

variable "disk_type" {
  description = ""
  type        = string
}
