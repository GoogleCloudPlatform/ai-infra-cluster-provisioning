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

variable "region" {
  description = "GCP region where to create resources."
  type        = string
}

variable "deployment_name" {
  description = "HPC-Toolkit deployment name"
  type        = string
}

variable "network_id" {
  description = "ID of the GCE VPC network to which the cluster will be connected"
  type        = string
}

variable "subnetwork_self_link" {
  description = "The self_link of the GCE VPC subnetwork to which the cluster will be connected"
  type        = string
}

variable "min_master_version" {
  description = "The GKE version to use to create the cluster."
  type    = string
}

# GKE Dataplane V2 support. This setting is immutable on clusters.
# https://cloud.google.com/kubernetes-engine/docs/concepts/dataplane-v2
variable "enable_dataplane_v2" {
  description = "Dataplane v2 provides better security, scalability, consistency and operations."
  type        = bool
}

# Security Note: do not use the default GCE service account. create a dedicated
# service account with least privileges.
#
# For example, see the gke-cluster Service Account in the following projects:
# http://google3/configs/cloud/gong/org_hierarchy/google.com/products/alphabetcloud/reference/project.abcloud-ref-prod/iam_policy.yaml
# http://google3/configs/cloud/gong/org_hierarchy/google.com/products/alphabetcloud/reference/project.abcloud-ref-gcr/iam_policy.yaml
variable "service_account_email" {
  description = "Email address of the service account to use for running nodes."
  type        = string
}

variable "node_pools" {
  description = "The list of nodepools for the GKE cluster."
  type = list(object({
    name                     = string
    zone                     = string
    node_count               = number
    machine_type             = string
    disk_size_gb             = number
    disk_type                = string
    guest_accelerator_count  = number
    guest_accelerator_type   = string
    enable_compact_placement = bool
  }))
}
