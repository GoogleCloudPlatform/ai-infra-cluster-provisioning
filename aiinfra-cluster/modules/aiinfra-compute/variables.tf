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
  description = "Project in which the HPC deployment will be created"
  type        = string
}

variable "region" {
  description = "Region in which the HPC deployment will be created"
  type        = string
}

variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 1
}

variable "instance_image" {
  description = "Instance Image"
  type = object({
    name    = string,
    family  = string,
    project = string
  })
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

variable "name_prefix" {
  description = "Name Prefix"
  type        = string
  default     = null
}

variable "disable_public_ips" {
  description = "If set to true, instances will not have public IPs"
  type        = bool
  default     = false
}

variable "machine_type" {
  description = "Machine type to use for the instance creation"
  type        = string
  default     = "c2-standard-60"
}

variable "network_storage" {
  description = "An array of network attached storage mounts to be configured."
  type = list(object({
    server_ip     = string,
    remote_mount  = string,
    local_mount   = string,
    fs_type       = string,
    mount_options = string
  }))
  default = []
}

variable "deployment_name" {
  description = "Name of the deployment, used to name the cluster"
  type        = string
}

variable "labels" {
  description = "Labels to add to the instances. List key, value pairs."
  type        = any
}

variable "service_account" {
  description = "Service account to attach to the instance. See https://www.terraform.io/docs/providers/google/r/compute_instance_template.html#service_account."
  type = object({
    email  = string,
    scopes = set(string)
  })
  default = {
    email = null
    scopes = ["https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
    "https://www.googleapis.com/auth/trace.append"]
  }
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

variable "zone" {
  description = "Compute Platform zone"
  type        = string
}

variable "metadata" {
  description = "Metadata, provided as a map"
  type        = map(string)
  default     = {}
}

variable "startup_script" {
  description = "Startup script used on the instance"
  type        = string
  default     = null
}

variable "guest_accelerator" {
  description = "The type and count of accelerator card attached to the instance."
  type = object({
    type  = string,
    count = number
  })
  default = null
}

variable "on_host_maintenance" {
  description = "Describes maintenance behavior for the instance. If left blank this will default to `MIGRATE` except for when `placement_policy`, spot provisioning, or GPUs require it to be `TERMINATE`"
  type        = string
  default     = null
  validation {
    condition     = var.on_host_maintenance == null ? true : contains(["MIGRATE", "TERMINATE"], var.on_host_maintenance)
    error_message = "When set, the on_host_maintenance must be set to MIGRATE or TERMINATE."
  }
}

variable "bandwidth_tier" {
  description = <<EOT
  Tier 1 bandwidth increases the maximum egress bandwidth for VMs.
  Using the `tier_1_enabled` setting will enable both gVNIC and TIER_1 higher bandwidth networking.
  Using the `gvnic_enabled` setting will only enable gVNIC and will not enable TIER_1.
  Note that TIER_1 only works with specific machine families & shapes and must be using an image that supports gVNIC. See [official docs](https://cloud.google.com/compute/docs/networking/configure-vm-with-high-bandwidth-configuration) for more details.
  EOT
  type        = string
  default     = "gvnic_enabled"

  validation {
    condition     = contains(["not_enabled", "gvnic_enabled", "tier_1_enabled"], var.bandwidth_tier)
    error_message = "Allowed values for bandwidth_tier are 'not_enabled', 'gvnic_enabled', or  'tier_1_enabled'."
  }
}

variable "placement_policy" {
  description = "Control where your VM instances are physically located relative to each other within a zone."
  type = object({
    vm_count                  = number,
    availability_domain_count = number,
    collocation               = string,
  })
  default = null
}

variable "spot" {
  description = "Provision VMs using discounted Spot pricing, allowing for preemption"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Network tags, provided as a list"
  type        = list(string)
  default     = []
}

variable "threads_per_core" {
  description = <<-EOT
  Sets the number of threads per physical core. By setting threads_per_core
  to 2, Simultaneous Multithreading (SMT) is enabled extending the total number
  of virtual cores. For example, a machine of type c2-standard-60 will have 60
  virtual cores with threads_per_core equal to 2. With threads_per_core equal
  to 1 (SMT turned off), only the 30 physical cores will be available on the VM.

  The default value of \"0\" will turn off SMT for supported machine types, and
  will fall back to GCE defaults for unsupported machine types (t2d, shared-core 
  instances, or instances with less than 2 vCPU). 

  Disabling SMT can be more performant in many HPC workloads, therefore it is
  disabled by default where compatible.

  null = SMT configuration will use the GCE defaults for the machine type
  0 = SMT will be disabled where compatible (default)
  1 = SMT will always be disabled (will fail on incompatible machine types)
  2 = SMT will always be enabled (will fail on incompatible machine types)
  EOT
  type        = number
  default     = 0

  validation {
    condition     = var.threads_per_core == null || try(var.threads_per_core >= 0, false) && try(var.threads_per_core <= 2, false)
    error_message = "Allowed values for threads_per_core are \"null\", \"0\", \"1\", \"2\"."
  }

}

variable "enable_oslogin" {
  description = "Enable or Disable OS Login with \"ENABLE\" or \"DISABLE\". Set to \"INHERIT\" to inherit project OS Login setting."
  type        = string
  default     = "ENABLE"
  validation {
    condition     = var.enable_oslogin == null ? false : contains(["ENABLE", "DISABLE", "INHERIT"], var.enable_oslogin)
    error_message = "Allowed string values for var.enable_oslogin are \"ENABLE\", \"DISABLE\", or \"INHERIT\"."
  }
}

variable "enable_notebook" {
  description = "The flag to enable jupyter notebook initialization."
  type        = bool
  default     = true
}

variable "network_interfaces" {
  type = list(object({
    network            = string,
    subnetwork         = string,
    subnetwork_project = string,
    network_ip         = string,
    nic_type           = string,
    stack_type         = string,
    queue_count        = number,
    access_config = list(object({
      nat_ip                 = string,
      public_ptr_domain_name = string,
      network_tier           = string
    })),
    ipv6_access_config = list(object({
      public_ptr_domain_name = string,
      network_tier           = string
    })),
    alias_ip_range = list(object({
      ip_cidr_range         = string,
      subnetwork_range_name = string
    }))
  }))
  default = []
  validation {
    condition = alltrue([
      for ni in var.network_interfaces : (ni.network == null) != (ni.subnetwork == null)
    ])
    error_message = "All additional network interfaces must define either \"network\" or \"subnetwork\", but not both."
  }
  validation {
    condition = alltrue([
      for ni in var.network_interfaces : ni.nic_type == "GVNIC" || ni.nic_type == "VIRTIO_NET" || ni.nic_type == null
    ])
    error_message = "In the variable network_interfaces, field \"nic_type\" must be either \"GVNIC\", \"VIRTIO_NET\" or null."
  }
  validation {
    condition = alltrue([
      for ni in var.network_interfaces : ni.stack_type == "IPV4_ONLY" || ni.stack_type == "IPV4_IPV6" || ni.stack_type == null
    ])
    error_message = "In the variable network_interfaces, field \"stack_type\" must be either \"IPV4_ONLY\", \"IPV4_IPV6\" or null."
  }
}

variable "orchestrator_type" {
  description = "The job orchestrator to be used, can be either ray (default), slurm or gke."
  type        = string

  validation {
    condition     = contains(["ray", "slurm", "gke", "none"], var.orchestrator_type)
    error_message = "Variable orchestrator_type must be either ray, slurm, gke or none."
  }
}

variable "slurm_node_count_static" {
  description = "Number of statically allocated nodes in compute partition"
  type        = number
}

variable "slurm_node_count_dynamic_max" {
  description = "Maximum number of dynamically allocated nodes allowed in compute partition"
  type        = number
}

variable "slurm_network_storage" {
  description = "Storage to mount on all slurm instances"
  type = list(object({
    server_ip             = string,
    remote_mount          = string,
    local_mount           = string,
    fs_type               = string,
    mount_options         = string,
    client_install_runner = map(string)
    mount_runner          = map(string)
  }))
  default = []
}

variable "gke_version" {
  description = "The GKE version to use to create the cluster."
  default = null
  type    = string
}

variable "node_pools" {
  description                = "The list of nodepools for the GKE cluster."
  type                       = list(object({
    name                     = string
    zone                     = string
    node_count               = number
    machine_type             = string
    guest_accelerator_count  = number
    guest_accelerator_type   = string
    enable_compact_placement = bool
  }))
  default                   = []
}
