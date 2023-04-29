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

variable "project" {
  description = "Name of the project to use for instantiating clusters."
  type        = string
}

variable "gke_cluster_endpoint" {
  description = "Kubernetes cluster API endpoint."
  type        = string
  default     = ""
}

variable "gke_certificate_authority_data" {
  description = "Kubernetes cluster cluster CA certificate."
  type        = string
  default     = ""
}

variable "gke_token" {
  description = "Kubernetes cluster access token."
  type        = string
  default     = ""
}

variable "kubernetes_service_account_name" {
  description = "The Kubernetes Service Account name."
  type        = string
  default     = "aiinfra-gke-sa"
}

variable "kubernetes_service_account_namespace" {
  description = "The Kubernetes Service Account namespace."
  type        = string
  default     = "default"
}

variable "node_service_account" {
  description = "The Google Service Account name."
  type        = string
  default     = ""
}

variable "enable_k8s_setup" {
  description = "Flag to represent if kubernetes setup is needed."
  type        = bool
  default     = false
}