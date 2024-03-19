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

variable "enable_gce_gke_gpu_utilization_widgets" {
  description = "Add GKE GPU utilization widgets to the dashboard."
  type        = bool
}

variable "enable_nvidia_dcgm_widgets" {
  description = "Add Nvidia DCGM widgets to the dashboard."
  type        = bool
}

variable "enable_nvidia_nvml_widgets" {
  description = "Add Nvidia NVML widgets to the dashboard."
  type        = bool
}

variable "project_id" {
  description = "GCP Project ID to which the cluster will be deployed."
  type        = string
}

variable "resource_prefix" {
  description = "Arbitrary string with which all names of newly created resources will be prefixed."
  type        = string
}
