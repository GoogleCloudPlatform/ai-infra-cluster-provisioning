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

locals {
  machine_image = {
    family  = var.machine_image.family != "" ? var.machine_image.family : null
    name    = var.machine_image.name != "" ? var.machine_image.name : null
    project = var.machine_image.project
  }


  _image_or_family = coalesce(
    local.machine_image.family,
    local.machine_image.name,
  )
  nic_type = anytrue([
    for pattern in ["debian-11", "ubuntu", "gvnic", "cos"]
    : length(regexall(pattern, local._image_or_family)) > 0
  ]) ? "GVNIC" : "VIRTIO_NET"


  _machine_image_is_dlvm = contains(
    [
      "deeplearning-platform-release",
      "ml-images",
    ],
    local.machine_image.project
  )
  metadata = merge(
    {
      VmDnsSetting          = "ZonalPreferred"
      install-nvidia-driver = "True"
      enable-oslogin        = "TRUE"
    },
    local._machine_image_is_dlvm ? {
      proxy-mode = "project_editors"
    } : {},
    var.startup_script != null ? {
      startup-script = var.startup_script
    } : {},
    var.metadata != null ? var.metadata : {},
  )


  service_account = var.service_account != null ? var.service_account : {
    email  = data.google_compute_default_service_account.account.email
    scopes = ["cloud-platform"]
  }
}

data "google_compute_default_service_account" "account" {
  project = var.project_id
}

data "google_compute_image" "image" {
  name    = var.machine_image.name
  family  = var.machine_image.family
  project = var.machine_image.project
}

module "resource_policy" {
  source = "../resource_policy"
  count  = var.use_compact_placement_policy ? 1 : 0

  project_id                    = var.project_id
  region                        = var.region
  new_resource_policy_name      = var.existing_resource_policy_name == null ? var.resource_prefix : null
  existing_resource_policy_name = var.existing_resource_policy_name == null ? null : var.existing_resource_policy_name
}

resource "google_compute_instance_template" "template" {
  provider = google-beta

  labels       = var.labels
  machine_type = var.machine_type
  metadata     = local.metadata
  name         = var.use_static_naming ? var.resource_prefix : null
  name_prefix  = var.use_static_naming ? null : var.resource_prefix
  project      = var.project_id
  region       = var.region
  resource_policies = var.use_compact_placement_policy ? [
    module.resource_policy[0].resource_self_link
  ] : []

  disk {
    auto_delete  = true
    boot         = true
    disk_size_gb = var.disk_size_gb
    disk_type    = var.disk_type
    source_image = data.google_compute_image.image.self_link
  }

  dynamic "network_interface" {
    for_each = toset(range(length(var.subnetwork_self_links)))
    content {
      network            = var.network_self_links[network_interface.value]
      nic_type           = local.nic_type
      subnetwork         = var.subnetwork_self_links[network_interface.value]
      subnetwork_project = var.project_id

      dynamic "access_config" {
        for_each = network_interface.value == 0 ? [1] : []
        content {
          nat_ip                 = null
          network_tier           = null
          public_ptr_domain_name = null
        }
      }
    }
  }

  scheduling {
    automatic_restart    = true
    maintenance_interval = var.maintenance_interval
    on_host_maintenance  = "TERMINATE"
    preemptible          = false
    provisioning_model   = null
  }

  service_account {
    email  = local.service_account.email
    scopes = local.service_account.scopes
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      metadata["ssh-keys"],
    ]
  }
}
