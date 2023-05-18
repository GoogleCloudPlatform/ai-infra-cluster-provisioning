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
  description = "GCP Project ID to which the cluster will be deployed."
  type        = string
}

variable "resource_prefix" {
  description = "Arbitrary string with which all names of newly created resources will be prefixed."
  type        = string
}

variable "region" {
  description = "The region in which the cluster master will be created. The cluster will be a regional cluster with multiple masters spread across zones in the region, and with default node locations in those zones as well."
  type        = string
}

variable "gke_version" {
  description = <<-EOT
    The GKE version to be used as the minimum version of the master. The default value for that is latest master version.
    More details can be found [here](https://cloud.google.com/kubernetes-engine/versioning#specifying_cluster_version)

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#name), [gcloud](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create#--name).
    EOT
  type        = string
  default     = null
}

variable "network_config" {
  description = <<-EOT
    The network configuration to specify the type of VPC to be used.

    Possible values: `["default", "new_multi_nic", "new_single_nic"]`
    EOT
  type        = string
  default     = "default"

  validation {
    condition = contains(
      ["default", "new_multi_nic", "new_single_nic"],
      var.network_config
    )
    error_message = "network_config must be one of ['default', 'new_multi_nic', 'new_single_nic']."
  }
}

variable "disk_size_gb" {
  description = <<-EOT
    Size of the disk attached to each node, specified in GB. The smallest allowed disk size is 10GB. Defaults to 200GB.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#disk_size_gb), [gcloud](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create#--disk-size).
    EOT
  type        = number
  default     = 200
}

variable "disk_type" {
  description = <<-EOT
    Type of the disk attached to each node. The default disk type is 'pd-standard'

    Possible values: `["pd-ssd", "local-ssd", "pd-balanced", "pd-standard"]`

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#disk_type), [gcloud](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create#--disk-type).
    EOT
  type        = string
  default     = "pd-standard"
}

variable "node_service_account" {
  description = <<-EOT
    The service account to be used by the Node VMs. If not specified, the "default" service account is used.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#nested_node_config), [gcloud](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create#--service-account).
    EOT
  type        = string
  default     = null
}

variable "enable_gke_dashboard" {
  description = <<-EOT
    Flag to enable GPU usage dashboards for the GKE cluster.
    EOT
  type        = bool
  default     = true

  validation {
    condition     = var.enable_gke_dashboard != null
    error_message = "must not be null"
  }
}

variable "node_pools" {
  description = <<-EOT
    The list of node pools for the GKE cluster.
    ```
    zone: The zone in which the node pool's nodes should be located. Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool.html#node_locations)
    node_count: The number of nodes per node pool. This field can be used to update the number of nodes per node pool. Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool.html#node_count)
    machine_type: The name of a Google Compute Engine machine type. Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#machine_type)
    guest_accelerator: This block is to provide information about GPUs. Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#nested_guest_accelerator)
    This must be `null` when `machine_type` is of an [accelerator-optimized machine family](https://cloud.google.com/compute/docs/accelerator-optimized-machines)
        guest_accelerator.type: The accelerator type resource to expose to this instance.
        guest_accelerator.count: The number of the guest accelerator cards exposed to this instance.
    enable_compact_placement: Specifies a custom placement policy for the nodes. Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool.html#placement_policy)
    ```
    EOT
  type = list(object({
    zone         = string,
    node_count   = number,
    machine_type = string,
    guest_accelerator = object({
      type  = string,
      count = number
    })
    enable_compact_placement = bool
  }))
}

variable "kubernetes_setup_config" {
  description = <<-EOT
    The configuration for setting up Kubernetes after GKE cluster is created.
    ```
    enable_kubernetes_setup: Flag to enable kubernetes setup. Default value is `true`.
    kubernetes_service_account_name: The KSA (kubernetes service account) name to be used for Pods. Default value is `aiinfra-gke-sa`.
    kubernetes_service_account_namespace: The KSA (kubernetes service account) namespace to be used for Pods. Default value is `default`.
    ```

    Related Docs: [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
    EOT
  type = object({
    enable_kubernetes_setup              = bool,
    kubernetes_service_account_name      = string,
    kubernetes_service_account_namespace = string
  })
  default = null
}
