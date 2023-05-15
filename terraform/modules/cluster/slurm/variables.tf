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
    List of partition configurations for the Slurm cluster. Each object in this list describes a separate partition in the cluster. Slurm organizes nodes into node groups and node groups into partitions. To make this simple, each partition will consist of exactly one node group; subsequently, each partition configuration will also configure the underlying node group.

    Related docs: [hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit/tree/main/community/modules/scheduler/schedmd-slurm-gcp-v5-controller#input_partition), [slurm-gcp](https://github.com/SchedMD/slurm-gcp/blob/master/terraform/slurm_cluster/modules/slurm_controller_instance/README_TF.md#input_partitions), [schedmd](https://slurm.schedmd.com/slurm.conf.html#SECTION_PARTITION-CONFIGURATION).

    ------------
    `compute_partitions[*].node_count_static`

    Number of nodes within this partition.

    Related docs: [hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit/tree/main/community/modules/compute/schedmd-slurm-gcp-v5-node-group#input_node_count_static).

    ------------
    `compute_partitions[*].partition_name`

    Related docs: [hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit/tree/main/community/modules/compute/schedmd-slurm-gcp-v5-partition#input_partition_name), [slurm-gcp](https://github.com/SchedMD/slurm-gcp/blob/master/terraform/slurm_cluster/modules/slurm_partition/README_TF.md#input_partition_name), [schedmd](https://slurm.schedmd.com/slurm.conf.html#OPT_PartitionName).

    ------------
    `compute_partitions[*].zone`

    Zone in which the partition’s nodes should be located.

    Related docs: [hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit/tree/main/community/modules/compute/schedmd-slurm-gcp-v5-partition#input_zone).

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
    `compute_partitions[*].guest_accelerator`

    List of the type and count of accelerator cards attached to each instance. This must be `null` when `machine_type` is of an [accelerator-optimized machine family](https://cloud.google.com/compute/docs/accelerator-optimized-machines) such as A2 or G2. Defaults to `null`.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#guest_accelerator), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--accelerator).

    ------
    `compute_partitions[*].guest_accelerator.count`

    The number of the guest accelerator cards exposed to each instance.

    ------
    `compute_partitions[*].guest_accelerator.type`

    The accelerator type resource to expose to each instance.

    [Possible values](https://cloud.google.com/compute/docs/gpus#nvidia_gpus_for_compute_workloads): `["nvidia-tesla-k80", "nvidia-tesla-p100", "nvidia-tesla-p4", "nvidia-tesla-t4", "nvidia-tesla-v100"]`.
    
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
    `compute_partitions[*].machine_type`

    The name of a Google Compute Engine machine type. There are [many possible values](https://cloud.google.com/compute/docs/machine-resource). Defaults to `"a2-highgpu-2g"`.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#machine_type), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--machine-type).

    ------------
    `compute_partitions[*].startup_script`

    Shell script -- the actual script (not the filename) -- to run at boot. Defaults to `null`.

    ------------
    `compute_partitions[*].startup_script_file`

    Filename of a shell script to run at boot. Defaults to `null`.
    EOT

  type = list(object({
    node_count_static = number
    partition_name    = string
    zone              = string

    disk_size_gb = number
    disk_type    = string
    guest_accelerator = object({
      count = number
      type  = string
    })
    machine_type        = string
    startup_script      = string
    startup_script_file = string
  }))
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

    Size of the disk attached to each node, specified in GB. Defaults to 128.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#disk_size_gb), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--boot-disk-size).

    ------------
    `controller_var.disk_type`

    Type of the disk attached to each node. Defaults to `"pd-standard"`.

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

    The name of a Google Compute Engine machine type. There are [many possible values](https://cloud.google.com/compute/docs/machine-resource). Defaults to `"a2-highgpu-2g"`

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#machine_type), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--machine-type).

    ------------
    `controller_var.startup_script`

    Shell script -- the actual script (not the filename) -- to run at boot. Defaults to `null`.

    ------------
    `controller_var.startup_script_file`

    Filename of a shell script to run at boot. Defaults to `null`.
    EOT

  type = object({
    disk_size_gb        = number
    disk_type           = string
    machine_type        = string
    startup_script      = string
    startup_script_file = string
    zone                = string
  })
  default = null
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

variable "login_var" {
  description = <<-EOT
    Login node configuration.

    ------------
    `login_var.zone`

    Zone in which the login node should be located. Defaults to the first compute partition's zone.

    Related docs: [hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit/tree/main/community/modules/compute/schedmd-slurm-gcp-v5-partition#input_zone).

    ------------
    `login_var.disk_size_gb`

    Size of the disk attached to each node, specified in GB. Defaults to 128.

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

    The name of a Google Compute Engine machine type. There are [many possible values](https://cloud.google.com/compute/docs/machine-resource). Defaults to `"a2-highgpu-2g"`

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#machine_type), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--machine-type).

    ------------
    `login_var.startup_script`

    Shell script -- the actual script (not the filename) -- to run at boot. Defaults to `null`.

    ------------
    `login_var.startup_script_file`

    Filename of a shell script to run at boot. Defaults to `null`.
    EOT

  type = object({
    disk_size_gb        = number
    disk_type           = string
    machine_type        = string
    startup_script      = string
    startup_script_file = string
    zone                = string
  })
  default = null
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
