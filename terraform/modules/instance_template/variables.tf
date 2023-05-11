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

variable "disk_size_gb" {
  description = <<-EOT
    The size of the image in gigabytes for the boot disk of each instance.

    Related docs:
    - [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#disk_size_gb
    - [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--boot-disk-size)"
    EOT
  type        = number
}

variable "disk_type" {
  description = <<-EOT
    The GCE disk type for the boot disk of each instance.

    Possible values:
    - `"pd-ssd"`
    - `"local-ssd"`
    - `"pd-balanced"`
    - `"pd-standard"`

    Related docs:
    - [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#disk_type)
    - [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--boot-disk-type)"
    EOT
  type        = string
}

variable "guest_accelerator" {
  description = <<-EOT
    List of the type and count of accelerator cards attached to each instance.
    This must be `null` when `machine_type` is of an
    [accelerator-optimized machine family](https://cloud.google.com/compute/docs/accelerator-optimized-machines)
    such as A2 or G2.

    Related docs:
    - [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#guest_accelerator)
    - [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--accelerator)

    ### `guest_accelerator.count`

    The number of the guest accelerator cards exposed to each instance.

    ### `guest_accelerator.type`

    The accelerator type resource to expose to each instance.

    Possible values:
    - `"nvidia-tesla-k80"`
    - `"nvidia-tesla-p100"`
    - `"nvidia-tesla-p4"`
    - `"nvidia-tesla-t4"`
    - `"nvidia-tesla-v100"`

    Related docs:
    - [possible values](https://cloud.google.com/compute/docs/gpus#nvidia_gpus_for_compute_workloads)
    EOT
  type = object({
    count = number
    type  = string
  })
}

variable "machine_image" {
  description = <<-EOT
    The image with which this disk will initialize.

    Related docs:
    - [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#source_image)

    ### `machine_image.family`

    The family of images from which the latest non-deprecated image will be selected. Conflicts with `machine_image.name`.

    Related docs:
    - [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image#name)
    - [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--image-family)

    ### `machine_image.name`

    The name of a specific image. Conflicts with `machin_image.family`.

    Related docs:
    - [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image#name)
    - [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--image)

    ### `machine_image.project`

    The project_id to which this image belongs.

    Related docs:
    - [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image#project)
    - [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--image-project)
    EOT
  type = object({
    family  = string
    name    = string
    project = string
  })

  validation {
    condition = (
      var.machine_image != null
      // project is non-empty
      && alltrue([
        for empty in [null, ""]
        : var.machine_image.project != empty
      ])
      // at least one is non-empty
      && anytrue([
        for value in [var.machine_image.name, var.machine_image.family]
        : alltrue([for empty in [null, ""] : value != empty])
      ])
      // at least one is empty
      && anytrue([
        for value in [var.machine_image.name, var.machine_image.family]
        : anytrue([for empty in [null, ""] : value == empty])
      ])
    )
    error_message = "project must be non-empty exactly one of family or name must be non-empty"
  }
}

variable "machine_type" {
  description = <<-EOT
    The name of a Google Compute Engine machine type.

    Related docs:
    - [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#machine_type)
    - [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--machine-type)
    EOT
  type        = string
}

variable "metadata" {
  description = <<-EOT
    Metadata key/value pairs to make available from within instances created from
    this template.

    Related docs:
    - [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#metadata)
    - [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--metadata)
    EOT
  type        = map(string)
}

variable "project_id" {
  description = <<-EOT
    The ID of the project in which the resource belongs.

    Related docs:
    - [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#project)
    EOT
  type        = string
}

variable "region" {
  description = <<-EOT
    An instance template is a global resource that is not bound to a zone or a
    region. However, you can still specify some regional resources in an
    instance template, which restricts the template to the region where that
    resource resides. For example, a custom subnetwork resource is tied to a
    specific region.

    Related docs:
    - [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#region)
    EOT
  type        = string
}

variable "resource_prefix" {
  description = <<-EOT
    Arbitrary string with which all names of newly created resources will be
    prefixed.
    EOT
  type        = string
}

variable "service_account" {
  description = <<-EOT
    Service account to attach to the instance.

    Related docs:
    - [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#service_account)

    ### `service_account.email`

    The service account e-mail address. If not given, the default Google
    Compute Engine service account is used.

    Related docs:
    - [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#email)
    - [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--service-account)

    ### `service_account.scopes`

    A list of service scopes. Both OAuth2 URLs and gcloud short names are
    supported. To allow full access to all Cloud APIs, use the
    `"cloud-platform"` scope. See a complete list of scopes
    [here](https://cloud.google.com/sdk/gcloud/reference/alpha/compute/instances/set-scopes#--scopes)

    Related docs:
    - [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#scopes)
    - [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--scopes)
    EOT
  type = object({
    email  = string,
    scopes = set(string)
  })
}

variable "startup_script" {
  description = <<-EOT
    Script to run at boot on each instance. This is here for convenience and
    will just be appended to `metadata` under the key `"startup-script"`.
    EOT
  type        = string
}

variable "subnetwork_self_links" {
  description = "Primary subnet self-links for all the VPCs."
  type        = list(string)

  validation {
    condition     = length(var.subnetwork_self_links) != 0
    error_message = "Must have one or more subnetwork self-link"
  }
}