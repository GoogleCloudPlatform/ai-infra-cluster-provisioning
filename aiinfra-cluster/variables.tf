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

variable "gcs_bucket_path" {
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
  description = "Boot disk type, can be either pd-ssd, local-ssd, or pd-standard."
  type        = string
  default     = "pd-standard"

  validation {
    condition     = contains(["pd-ssd", "local-ssd", "pd-standard"], var.disk_type)
    error_message = "Variable disk_type must be one of pd-ssd, local-ssd, or pd-standard."
  }
}

variable "network_config" {
  description = "The network configuration to specify the type of VPC to be used"
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

variable "local_filepath_list_to_copy" {
  description = "Comma separated list of local file paths to copy to the VMs."
  type        = string
  default     = ""
}

variable "orchestrator_type" {
  description = "The job orchestrator to be used"
  type        = string
  default     = "ray"

  validation {
    condition     = contains(["ray", "slurm"], var.orchestrator_type)
    error_message = "Variable orchestrator_type must be either ray or slurm."
  }
}

variable "startup_command" {
  description = "The startup command to be executed when the VM starts up."
  type        = string
  default = ""
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