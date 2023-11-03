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

variable "cluster_id" {
  description = "An identifier for the resource with format projects/<project_id>/locations/<region>/clusters/<name>."
  type        = string
  nullable    = false
}

variable "daemonsets" {
  description = "Daemonsets to install with kubectl apply -f <daemonset>"
  type        = map(string)
  nullable    = false

  validation {
    condition     = length(var.daemonsets) != 0
    error_message = "must specify at least one daemonset"
  }
}

variable "enable" {
  description = <<-EOT
    This module cannot have for_each, count, or depends_on attributes because
    it contains provider blocks. Conditionally enable this moduel by setting
    this variable.
    EOT
  type        = bool
  nullable    = false
}

variable "ksa" {
  description = <<-EOT
    The configuration for setting up Kubernetes Service Account (KSA) after GKE
    cluster is created.

    - `name`: The KSA name to be used for Pods
    - `namespace`: The KSA namespace to be used for Pods

    Related Docs: [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
    EOT
  type = object({
    name      = string
    namespace = string
  })
}

variable "gcp_sa" {
  description = <<-EOT
    Google Cloud Platform service account email to which the
    Kubernetes Service Account (KSA) will be bound.
    EOT
  type        = string
  nullable    = false
}

variable "project_id" {
  description = "Name of the project to use for instantiating clusters."
  type        = string
  nullable    = false
}
