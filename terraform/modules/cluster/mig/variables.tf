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

variable "target_size" {
  description = <<-EOT
    The number of running instances for this managed instance group.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_group_manager#target_size), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-groups/managed/create#--size).
    EOT
  type        = number
}

variable "zone" {
  description = <<-EOT
    The zone that instances in this group should be created in.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_group_manager#zone), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-groups/managed/create#--zone).
    EOT
  type        = string
}

// TODO: All `local_mount`s found in `gcsfuse_existing` and `filestore_new` should be visible within the container.
variable "container_image" {
  description = <<-EOT
    Container image to start on boot on each instance. When this is set, the default for machine_image will be changed to `{ project = "cos-cloud", family = "cos-stable" }`.
    EOT
  type        = string
  default     = null
}

variable "disk_size_gb" {
  description = <<-EOT
    The size of the image in gigabytes for the boot disk of each instance.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#disk_size_gb), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--boot-disk-size).
    EOT
  type        = number
  default     = 128
}

variable "disk_type" {
  description = <<-EOT
    The GCE disk type for the boot disk of each instance.

    Possible values: `["pd-ssd", "local-ssd", "pd-balanced", "pd-standard"]`

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#disk_type), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--boot-disk-type).
    EOT
  type        = string
  default     = "pd-standard"
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

variable "guest_accelerator" {
  description = <<-EOT
    List of the type and count of accelerator cards attached to each instance. This must be `null` when `machine_type` is of an [accelerator-optimized machine family](https://cloud.google.com/compute/docs/accelerator-optimized-machines) such as A2 or G2.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#guest_accelerator), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--accelerator).

    ------------
    `guest_accelerator.count`

    The number of the guest accelerator cards exposed to each instance.

    ------------
    `guest_accelerator.type`

    The accelerator type resource to expose to each instance.

    [Possible values](https://cloud.google.com/compute/docs/gpus#nvidia_gpus_for_compute_workloads): `["nvidia-tesla-k80", "nvidia-tesla-p100", "nvidia-tesla-p4", "nvidia-tesla-t4", "nvidia-tesla-v100"]`.
    EOT
  type = object({
    count = number
    type  = string
  })
  default = null
}

variable "enable_ops_agent" {
  description = <<-EOT
    Install [Google Cloud Ops Agent](https://cloud.google.com/stackdriver/docs/solutions/agents/ops-agent).
    EOT
  type        = bool
  default     = true

  validation {
    condition     = var.enable_ops_agent != null
    error_message = "must not be null"
  }
}

variable "enable_ray" {
  description = "Install [Ray](https://docs.ray.io/en/latest/cluster/getting-started.html)."
  type        = bool
  default     = false

  validation {
    condition     = var.enable_ray != null
    error_message = "must not be null"
  }
}

variable "labels" {
  description = <<-EOT
    The resource labels (a map of key/value pairs) to be applied to the GPU cluster.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#labels), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--labels).
    EOT
  type        = map(string)
  default     = {}
}

variable "machine_image" {
  description = <<-EOT
    The image with which this disk will initialize.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#source_image).

    ------------
    `machine_image.family`

    The family of images from which the latest non-deprecated image will be selected. Conflicts with `machine_image.name`.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image#name), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--image-family).

    ------------
    `machine_image.name`

    The name of a specific image. Conflicts with `machine_image.family`.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image#name), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--image).

    ------------
    `machine_image.project`

    The project_id to which this image belongs.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image#project), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--image-project).
    EOT
  type = object({
    family  = string
    name    = string
    project = string
  })
  default = null
}

variable "machine_type" {
  description = <<-EOT
    The name of a Google Compute Engine machine type. There are [many possible values](https://cloud.google.com/compute/docs/machine-resource).

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#machine_type), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--machine-type).
    EOT
  type        = string
  default     = "a2-highgpu-2g"
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

variable "startup_script" {
  description = "Shell script -- the actual script (not the filename)."
  type        = string
  default     = null
}

variable "startup_script_file" {
  description = "The full path in the VM to the shell script to be executed at VM startup."
  type        = string
  default     = null
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
