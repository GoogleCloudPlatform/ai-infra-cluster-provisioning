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

variable "region" {
  description = "GCP region where to create resources."
  type        = string
}

variable "zone" {
  description = "GCP zone where to create resources. Only use if multi_zonal is false."
  type        = string
}

variable "node_locations" {
  description = "Zones for a regional cluster, leave blank to auto select."
  type        = list(string)
  default     = null
}

variable "name" {
  description = "Name of the cluster, unique within the project."
  default = "main"
  type    = string
}

variable "gke_version" {
  description = "The GKE version to use to create the cluster."
  default = null
  type    = string
}

variable "network_self_link" {
  description = "The self link of the network to attach the VM."
  type        = string
  default     = "default"
}

variable "subnetwork_self_link" {
  description = "The self link of the subnetwork to attach the VM."
  type        = string
  default     = null
}

variable "disk_size_gb" {
  description = "Size of disk for instances."
  type        = number
  default     = 200
}

variable "disk_type" {
  description = "Disk type for instances."
  type        = string
  default     = "pd-standard"
}


# GKE Dataplane V2 support. This setting is immutable on clusters.
# https://cloud.google.com/kubernetes-engine/docs/concepts/dataplane-v2
variable "enable_dataplane_v2" {
  description = "Dataplane v2 provides better security, scalability, consistency and operations."
  default     = false
  type        = bool
}

# Security Note: do not use the default GCE service account. create a dedicated
# service account with least privileges.
#
# For example, see the gke-cluster Service Account in the following projects:
# http://google3/configs/cloud/gong/org_hierarchy/google.com/products/alphabetcloud/reference/project.abcloud-ref-prod/iam_policy.yaml
# http://google3/configs/cloud/gong/org_hierarchy/google.com/products/alphabetcloud/reference/project.abcloud-ref-gcr/iam_policy.yaml
variable "node_service_account" {
  description = "Email address of the service account to use for running nodes."
  type        = string
}

# List of Oauth scopes to attach to node isntnaces in your GKE cluster.
variable "scopes" {
  type = list(string)
  default = [
    # H4: we rely on CloudIAM for implementing least-priviledge on GCP, so
    # providing the SA a cloud-platform scope is safe, and simplified
    # debugging of access control issues.
    #
    # Additional scopes can be provided for access to non-GCP services.
    "https://www.googleapis.com/auth/cloud-platform",

    # The Gin scope can be removed if the none of the applications sends
    # logs to Gin.
    "https://www.googleapis.com/auth/dataaccessauditlogging",
  ]
}

variable "node_pools" {
  description = "The list of nodepools for the GKE cluster."
  type = list(object({
    name                     = string
    zone                     = string
    node_count               = number
    machine_type             = string
    guest_accelerator_count  = number
    guest_accelerator_type   = string
    enable_compact_placement = bool
  }))
}
