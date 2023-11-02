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

variable "cluster_id" {
  description = "An identifier for the resource with format projects/<project_id>/locations/<region>/clusters/<name>."
  type        = string
}

variable "gke_cluster_exists" {
  description = "If set to false then the kubernetes providers will not be configured."
  type        = bool
  default     = true
}

variable "install_nvidia_driver" {
  description = "If true will create a DaemonSet to install nvidia drivers."
  type        = bool
  default     = false
}

variable "setup_kubernetes_service_account" {
  description = <<-EOT
    If set, will configure a kubernetes service account and link it to a Google service account.

    Subfields:
    kubernetes_service_account_name: The Kubernetes Service Account name.
    kubernetes_service_account_namespace: The Kubernetes Service Account namespace.
    google_service_account_name: The Google Service Account name. Use empty string for default compute service account.
    EOT
  type = object({
    kubernetes_service_account_name      = string
    kubernetes_service_account_namespace = string
    google_service_account_name          = string
  })
  default = null
}

variable "node_pool_ids" {
  description = "dummy"
  type = list(string)
  default = []
}
