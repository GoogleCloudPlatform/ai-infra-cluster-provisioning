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

variable "instance_groups" {
  description = <<-EOT
    Required Fields:
    - `target_size`: The number of running instances for this managed instance group. Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_group_manager#target_size), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-groups/managed/create#--size).
    - `zone`: The zone that instances in this group should be created in. Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_group_manager#zone), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-groups/managed/create#--zone).
    - `machine_type`: (Optional)The name of a Google Compute Engine machine type. There are [many possible values](https://cloud.google.com/compute/docs/machine-resource). Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#machine_type), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--machine-type).
    - `existing_resource_policy_name`: (Optional) The existing resource policy.
    EOT
  type = list(object({
    zone                          = string
    target_size                   = number
    machine_type                  = optional(string, "a3-highgpu-8g")
    existing_resource_policy_name = optional(string, null)
  }))
  nullable = false

  validation {
    condition     = length(var.instance_groups) != 0
    error_message = "must have at least one instance group"
  }

  validation {
    condition = alltrue([
      for g in var.instance_groups : g.zone != null && g.target_size != null
    ])
    error_message = "zone and target_size must not be null"
  }
}

variable "project_id" {
  description = "GCP Project ID to which the cluster will be deployed."
  type        = string
  nullable    = false
}

variable "region" {
  description = "The region in which all instances will reside."
  type        = string
  nullable    = false
}

variable "resource_prefix" {
  description = "Arbitrary string with which all names of newly created resources will be prefixed."
  type        = string
  nullable    = false
}

variable "container" {
  description = <<-EOT
    Container image to start on boot on each instance. All `local_mount`s found in `filestore_new` and `gcsfuse_existing` will be visible within the container.

    Attributes:
    - `image`: docker image which will get pulled and started at boot on each instance (Related docs: [docker](https://docs.docker.com/engine/reference/commandline/build/#tag)).
    - `cmd`: arguments to the entrypoint of the docker image (Related docs: [docker](https://docs.docker.com/engine/reference/builder/#cmd)). Defaults to `[]`.
    - `run_at_boot`: automatically start a container on each instance when they are created (will still pull image at boot when set to `false`). Defaults to `true`.
    - `run_options`: the additional options to pass during docker run.
      - `custom`: any other `docker run` options (Related docs: [docker](https://docs.docker.com/engine/reference/commandline/run/#options)). `docker run` flags already added (`container.run_options.custom` will be appended to this list): `--detach --hostname $(hostname) --ipc host --name aiinfra --network host --privileged --restart always`. Defaults to `[]`.
      - `enable_cloud_logging`: the flag to enable GCP cloud logging (`--log-driver=gcplogs`) for the containers (Related docs: [docker](https://cloud.google.com/community/tutorials/docker-gcplogs-driver)). Defaults to `false`.
      - `env`: environment variables for the docker container (Related docs: [docker](https://docs.docker.com/engine/reference/commandline/run/#env)). Defaults to `{}`.

    EOT
  type = object({
    image       = string
    cmd         = string
    run_at_boot = bool
    run_options = object({
      custom               = list(string)
      enable_cloud_logging = bool
      env                  = map(string)
    })
  })
  default = null
}

variable "enable_install_gpu" {
  description = <<-EOT
    Setting this to false will disable a built-in startup script which:
    - installs GPU drivers
    - configures docker auth
    - installs iptable rules
    - installs NCCL and GPUDirectTCPX plugin

    Any installation replacements should be in the startup_script variable
    EOT
  type        = bool
  default     = true
  nullable    = false
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
  default     = "pd-ssd"
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

    ------------
    `filestore_new.zone`

    Location for filestore instance.

    Related docs: [hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit/tree/main/modules/file-system/filestore#input_zone).
    EOT
  type = list(object({
    filestore_tier = string
    local_mount    = string
    size_gb        = number
    zone           = string
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

variable "machine_image" {
  description = <<-EOT
    The image with which this disk will initialize. This image must be in the project `cos-cloud`.

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
  default = {
    family  = "cos-stable"
    name    = null
    project = "cos-cloud"
  }
}

variable "maintenance_interval" {
  description = <<-EOT
  Specifies the frequency of planned maintenance events. 'PERIODIC' is th only supported value for maintenance_interval.

  Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#maintenance_interval).
    EOT
  type        = string
  default     = null
}

variable "metadata" {
  description = <<-EOT
    GCE metadata to attach to each instance.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#metadata), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--metadata).
    EOT
  type        = map(string)
  default     = {}
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

variable "startup_script" {
  description = "Shell script -- the actual script (not the filename)."
  type        = string
  default     = null
}

variable "use_compact_placement_policy" {
  description = "The flag to create and use a superblock level compact placement policy for the instances. Currently GCE supports using only 1 placement policy."
  type        = bool
  default     = false
}

variable "wait_for_instances" {
  description = <<-EOT
    Whether to wait for all instances to be created/updated before returning. Note that if this is set to true and the operation does not succeed, Terraform will continue trying until it times out.

    Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_instance_group_manager#wait_for_instances). 
    EOT
  type        = bool
  default     = true
}
