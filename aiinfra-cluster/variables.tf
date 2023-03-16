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
  description = "The project_id to create the resources for GPU cluster."
  type        = string
}

variable "service_account" {
  description = "Service account to attach to the instance. See https://www.terraform.io/docs/providers/google/r/compute_instance_template.html#service_account."
  type = object({
    email  = string,
    scopes = set(string)
  })
  default = {
    email = null
    scopes = ["https://www.googleapis.com/auth/devstorage.read_write",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
    "https://www.googleapis.com/auth/trace.append"]
  }
}

variable "name_prefix" {
  description = "The name prefix to be used for creating resources."
  type        = string
}

variable "deployment_name" {
  description = "The deployment name. Default value is name_prefix-depl."
  type        = string
  default     = null
}

variable "region" {
  description = "The region to create the GPU cluster."
  type        = string
}

variable "zone" {
  description = "The zone to create the GPU cluster."
  type        = string
}

variable "machine_type" {
  description = "The VM type to use for compute."
  type        = string
}

variable "instance_count" {
  description = "The number of VM instances."
  type        = number
}

variable "accelerator_type" {
  description = "The accelerator (GPU) type."
  type        = string
}

variable "gpu_per_vm" {
  description = "The number of GPUs per VM."
  type        = number
}

variable "instance_image" {
  description = "The VM instance image."
  type        = map
}

variable "disk_size_gb" {
  description = "Size of disk for VM instances."
  type        = number
  default     = 1000
}

variable "disk_type" {
  description = "Boot disk type, can be either pd-ssd, local-ssd, or pd-standard (default)."
  type        = string
  default     = "pd-standard"

  validation {
    condition     = contains(["pd-ssd", "local-ssd", "pd-standard"], var.disk_type)
    error_message = "Variable disk_type must be one of pd-ssd, local-ssd, or pd-standard."
  }
}

variable "labels" {
  description = "Lables for the GPU cluster resources."
  type        = map
}

variable "metadata" {
  description = "Metadata for the VM instance."
  type        = map
}

variable "gcs_bucket_path" {
  description = "The GCS bucket path to use for startup scripts."
  type        = string
}

variable "network_config" {
  description = "The network configuration to specify the type of VPC to be used, can be either default_network (default), new_network or multi_nic_network"
  type        = string
  default     = "default_network"

  validation {
    condition     = contains(["default_network", "new_network", "multi_nic_network"], var.network_config)
    error_message = "Variable network_config must be one of default_network, new_network, or multi_nic_network."
  }
}

variable "gcs_mount_list" {
  description = "Comma separate list of GCS buckets to be mounted in the VMs."
  type        = string
  default     = ""
}

variable "nfs_filestore_list" {
  description = "Comma separated list of NFS filestore paths to be created for the VMs."
  type        = string
  default     = ""
}

variable "orchestrator_type" {
  description = "The job orchestrator to be used, can be either ray (default), slurm or gke."
  type        = string
  default     = "none"

  validation {
    condition     = contains(["ray", "slurm", "gke", "none"], var.orchestrator_type)
    error_message = "Variable orchestrator_type must be either ray, slurm, gke or none."
  }
}

variable "startup_command" {
  description = "The startup command to be executed when the VM starts up."
  type        = string
  default     = ""
}

variable "enable_ops_agent" {
  description = "The flag to enable Ops agent installation."
  type        = bool
  default     = true
}

variable "enable_notebook" {
  description = "The flag to enable jupyter notebook initialization."
  type        = bool
  default     = true
}

variable "local_dir_copy_list" {
  description = "The comma separated list of local directories to copy and destination path on the VMs. E.G.: <local/dir/path>:<dest/path>,"
  type        = string
  default     = ""

  validation {
    condition = alltrue([
      for part in compact(split(",", trimspace(var.local_dir_copy_list))) : length(trimspace(part)) == 0 || (can(fileset("${split(":", trimspace(part))[0]}", "**")) && length(split(":", trimspace(part))[1]) > 0)
    ])
    error_message = "All directory paths should be full path and exist on the machine. Destination path should be provided for all directory paths."
  }
}

variable "gke_node_pool_count" {
  description = "The number of homogeneous node pools for GKE cluster."
  type        = number
  default     = 0
}

variable "gke_node_count_per_node_pool" {
  description = "The desired node count per node pool for GKE cluster. Creation will fail if at least this number of Nodes cannot be created."
  type        = number
  default     = 0
}

variable "custom_node_pools" {
  description               = "The list of custom nodepools for the GKE cluster."
  type                      = list(object({
    name                    = string
    node_count              = number
    machine_type            = string
    guest_accelerator_count = number
    guest_accelerator_type  = string
  }))
  default                   = []
}