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

variable "compute_partitions" {
  description = <<-EOT
    List of A3 partition configurations for the Slurm cluster. Each object in this list describes a separate partition in the cluster. Slurm organizes nodes into node groups and node groups into partitions. To make this simple, each partition will consist of exactly one node group; subsequently, each partition configuration will also configure the underlying node group.

    Related docs: [hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit/tree/main/community/modules/scheduler/schedmd-slurm-gcp-v5-controller#input_partition), [slurm-gcp](https://github.com/SchedMD/slurm-gcp/blob/master/terraform/slurm_cluster/modules/slurm_controller_instance/README_TF.md#input_partitions), [schedmd](https://slurm.schedmd.com/slurm.conf.html#SECTION_PARTITION-CONFIGURATION).

    ------------------------
    Required Fields

    ------------
    `compute_partitions[*].node_count_dynamic_max`

    Maximum number of dynamic nodes allowed in this partition.

    Related docs: [hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit/tree/main/community/modules/compute/schedmd-slurm-gcp-v5-node-group#input_node_count_dynamic_max).

    ------------
    `compute_partitions[*].node_count_static`

    Number of nodes to be statically created.

    Related docs: [hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit/tree/main/community/modules/compute/schedmd-slurm-gcp-v5-node-group#input_node_count_static).

    ------------
    `compute_partitions[*].partition_name`

    Related docs: [hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit/tree/main/community/modules/compute/schedmd-slurm-gcp-v5-partition#input_partition_name), [slurm-gcp](https://github.com/SchedMD/slurm-gcp/blob/master/terraform/slurm_cluster/modules/slurm_partition/README_TF.md#input_partition_name), [schedmd](https://slurm.schedmd.com/slurm.conf.html#OPT_PartitionName).

    ------------
    `compute_partitions[*].zone`

    Zone in which the partition’s nodes should be located.

    Related docs: [hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit/tree/main/community/modules/compute/schedmd-slurm-gcp-v5-partition#input_zone).


    ------------------------
    Optional Fields (set to `null` to get default values)

    ------------
    `compute_partitions[*].disk_size_gb`

    Size of the disk attached to each node, specified in GB. Defaults to 128.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#disk_size_gb), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--boot-disk-size).

    ------------
    `compute_partitions[*].disk_type`

    Type of the disk attached to each node. Defaults to `"pd-standard"`.

    Possible values: `["pd-standard", "pd-balanced", "pd-ssd"]`.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#disk_type).

    ------------
    `compute_partitions[*].machine_image`

    The image with which this disk will initialize.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#source_image).

    ------
    `compute_partitions[*].machine_image.family`

    The family of images from which the latest non-deprecated image will be selected. Conflicts with `compute_partitions[*].machine_image.name`. Defaults to `"schedmd-v5-slurm-22-05-8-ubuntu-2004-lts"`

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image#name), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--image-family).

    ------
    `compute_partitions[*].machine_image.name`

    The name of a specific image. Conflicts with `compute_partitions[*].machine_image.family`. Defaults to `null`.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image#name), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--image).

    ------
    `compute_partitions[*].machine_image.project`

    The project_id to which this image belongs. Defaults to `"schedmd-slurm-public"`

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image#project), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--image-project).

    ------------
    `compute_partitions[*].startup_script`

    Shell script -- the actual script (not the filename) -- to run at boot. Defaults to `null`.

    ------------
    `compute_partitions[*].startup_script_file`

    The full path in the VM to the shell script to be executed at VM startup. Defaults to `null`.
    EOT

  type = list(object({
    node_count_dynamic_max = number
    node_count_static      = number
    partition_name         = string
    zone                   = string

    disk_size_gb = number
    disk_type    = string
    machine_image = object({
      project = string
      family  = string
      name    = string
    })
    startup_script      = string
    startup_script_file = string
  }))

  validation {
    condition     = var.compute_partitions != null
    error_message = "compute_partitions must not be null"
  }

  validation {
    condition     = length(var.compute_partitions) > 0
    error_message = "compute_partitions must contain at least one element"
  }

  validation {
    condition = alltrue([
      for p in var.compute_partitions
      : p.node_count_static != null
    ])
    error_message = "compute_partitions[*].node_count_static must not be null"
  }

  validation {
    condition = alltrue([
      for p in var.compute_partitions
      : p.partition_name != null
    ])
    error_message = "compute_partitions[*].partition_name must not be null"
  }

  validation {
    condition = alltrue([
      for p in var.compute_partitions
      : p.zone != null
    ])
    error_message = "compute_partitions[*].zone must not be null"
  }
}

variable "controller_var" {
  description = <<-EOT
    Controller node configuration.

    ------------
    `controller_var.zone`

    Zone in which the controller node should be located. Defaults to the first compute partition's zone.

    Related docs: [hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit/tree/main/community/modules/compute/schedmd-slurm-gcp-v5-partition#input_zone).

    ------------
    `controller_var.disk_size_gb`

    Size of the disk attached to each node, specified in GB. Defaults to 50.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#disk_size_gb), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--boot-disk-size).

    ------------
    `controller_var.disk_type`

    Type of the disk attached to each node. Defaults to `"pd-ssd"`.

    Possible values: `["pd-standard", "pd-balanced", "pd-ssd"]`.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#disk_type).

    ------------
    `controller_var.machine_image`

    The image with which this disk will initialize.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#source_image).

    ------
    `controller_var.machine_image.family`

    The family of images from which the latest non-deprecated image will be selected. Conflicts with `controller_var.machine_image.name`. Defaults to `"schedmd-v5-slurm-22-05-8-ubuntu-2004-lts"`

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image#name), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--image-family).

    ------
    `controller_var.machine_image.name`

    The name of a specific image. Conflicts with `controller_var.machine_image.family`. Defaults to `null`.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image#name), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--image).

    ------
    `controller_var.machine_image.project`

    The project_id to which this image belongs. Defaults to `"schedmd-slurm-public"`

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image#project), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--image-project).

    ------------
    `controller_var.machine_type`

    The name of a Google Compute Engine machine type. There are [many possible values](https://cloud.google.com/compute/docs/machine-resource). Defaults to `"c2-standard-4"`

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#machine_type), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--machine-type).

    ------------
    `controller_var.startup_script`

    Shell script -- the actual script (not the filename) -- to run at boot. Defaults to `null`.

    ------------
    `controller_var.startup_script_file`

    The full path in the VM to the shell script to be executed at VM startup. Defaults to `null`.
    EOT

  type = object({
    disk_size_gb = number
    disk_type    = string
    machine_image = object({
      project = string
      family  = string
      name    = string
    })
    machine_type        = string
    startup_script      = string
    startup_script_file = string
    zone                = string
  })
  default = null
}

variable "enable_cleanup_compute" {
  description = <<-EOT
      Enables automatic cleanup of compute nodes and resource policies (e.g. placement groups) managed by this module, when cluster is destroyed.

      In order to use this, this `pip install` must be run in the same environment from which terraform is called: `pip3 install -r https://raw.githubusercontent.com/SchedMD/slurm-gcp/5.7.2/scripts/requirements.txt`

      Related docs: [hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit/tree/main/community/modules/scheduler/schedmd-slurm-gcp-v5-controller#input_enable_cleanup_compute)
      EOT
  type        = bool
  default     = false
}

variable "filestore_new" {
  description = <<-EOT
    Configurations to mount newly created network storage. Each object describes NFS file-servers to be hosted in Filestore.

    Related docs: [hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit/tree/main/modules/file-system/filestore#inputs).

    ------------
    `filestore_new.filestore_tier`

    The service tier of the instance.

    Possible values: `["BASIC_HDD", "BASIC_SSD", "HIGH_SCALE_SSD", "ENTERPRISE"]`.

    Related docs: [hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit/tree/main/modules/file-system/filestore#input_filestore_tier), [gcloud](https://cloud.google.com/sdk/gcloud/reference/filestore/instances/create#--tier).

    ------------
    `filestore_new.local_mount`

    Mountpoint for this filestore instance.

    Related docs: [hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit/tree/main/modules/file-system/filestore#input_local_mount).

    ------------
    `filestore_new.size_gb`

    Storage size of the filestore instance in GB.

    Related docs: [hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit/tree/main/modules/file-system/filestore#input_local_mount), [gcloud](https://cloud.google.com/sdk/gcloud/reference/filestore/instances/create#--file-share).
    EOT
  type = list(object({
    filestore_tier = string
    local_mount    = string
    size_gb        = number
  }))
  default = []
}

variable "gcsfuse_existing" {
  description = <<-EOT
    Configurations to mount existing network storage. Each object describes Cloud Storage Buckets to be mounted with Cloud Storage FUSE.

    Related docs: [hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit/tree/main/modules/file-system/pre-existing-network-storage#inputs).

    ------------
    `gcsfuse_existing.local_mount`

    The mount point where the contents of the device may be accessed after mounting.

    Related docs: [hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit/tree/main/modules/file-system/pre-existing-network-storage#input_local_mount).

    ------------
    `gcsfuse_existing.remote_mount`

    Bucket name without “gs://”.

    Related docs: [hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit/tree/main/modules/file-system/pre-existing-network-storage#input_remote_mount).
    EOT
  type = list(object({
    local_mount  = string
    remote_mount = string
  }))
  default = []
}

variable "labels" {
  description = <<-EOT
    The resource labels (a map of key/value pairs) to be applied to the GPU cluster.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#labels), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--labels).
    EOT
  type        = map(string)
  default     = {}
}

variable "login_var" {
  description = <<-EOT
    Login node configuration.

    ------------
    `login_var.zone`

    Zone in which the login node should be located. Defaults to the first compute partition's zone.

    Related docs: [hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit/tree/main/community/modules/compute/schedmd-slurm-gcp-v5-partition#input_zone).

    ------------
    `login_var.disk_size_gb`

    Size of the disk attached to each node, specified in GB. Defaults to 50.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#disk_size_gb), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--boot-disk-size).

    ------------
    `login_var.disk_type`

    Type of the disk attached to each node. Defaults to `"pd-standard"`.

    Possible values: `["pd-standard", "pd-balanced", "pd-ssd"]`.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#disk_type).

    ------------
    `login_var.machine_image`

    The image with which this disk will initialize.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#source_image).

    ------
    `login_var.machine_image.family`

    The family of images from which the latest non-deprecated image will be selected. Conflicts with `login_var.machine_image.name`. Defaults to `"schedmd-v5-slurm-22-05-8-ubuntu-2004-lts"`

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image#name), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--image-family).

    ------
    `login_var.machine_image.name`

    The name of a specific image. Conflicts with `login_var.machine_image.family`. Defaults to `null`.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image#name), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--image).

    ------
    `login_var.machine_image.project`

    The project_id to which this image belongs. Defaults to `"schedmd-slurm-public"`

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image#project), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--image-project).

    ------------
    `login_var.machine_type`

    The name of a Google Compute Engine machine type. There are [many possible values](https://cloud.google.com/compute/docs/machine-resource). Defaults to `"n2-standard-2"`

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#machine_type), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--machine-type).

    ------------
    `login_var.startup_script`

    Shell script -- the actual script (not the filename) -- to run at boot. Defaults to `null`.

    ------------
    `login_var.startup_script_file`

    The full path in the VM to the shell script to be executed at VM startup. Defaults to `null`.
    EOT

  type = object({
    disk_size_gb = number
    disk_type    = string
    machine_image = object({
      project = string
      family  = string
      name    = string
    })
    machine_type        = string
    startup_script      = string
    startup_script_file = string
    zone                = string
  })
  default = null
}

variable "network_existing" {
  description = "Existing network to attach to nic0. Setting to null will create a new network for it."
  type = object({
    network_name    = string
    subnetwork_name = string
  })
  default = null
}

variable "service_account" {
  description = <<-EOT
    Service account to attach to the instance.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#service_account).

    ------------
    `service_account.email`

    The service account e-mail address. If not given, the default Google Compute Engine service account is used.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#email), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--service-account).

    ------------
    `service_account.scopes`

    A list of service scopes. Both OAuth2 URLs and gcloud short names are supported. To allow full access to all Cloud APIs, use the `"cloud-platform"` scope. See a complete list of scopes [here](https://cloud.google.com/sdk/gcloud/reference/alpha/compute/instances/set-scopes#--scopes).

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#scopes), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--scopes).
    EOT
  type = object({
    email  = string,
    scopes = set(string)
  })
  default = null
}

variable "startup_script_gcs_bucket_path" {
  description = <<-EOT
    The storage bucket full path to be used for storing the startup script.
    Example: `gs://bucketName/dirName`

    If the value is not provided, then a default storage bucket will be created for the script execution.
    `storage.buckets.create` IAM permission is needed for creating the default storage bucket.
    EOT
  type        = string
  default     = null
}
