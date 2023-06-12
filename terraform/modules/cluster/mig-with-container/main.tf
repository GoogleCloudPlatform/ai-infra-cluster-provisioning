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
  region = join("-", slice(split("-", var.zone), 0, 2))

  machine_image = {
    project = "cos-cloud"
    family  = var.machine_image.family
    name    = var.machine_image.name
  }
}

module "network" {
  source = "../../common/network"

  network_config  = var.network_config
  project_id      = var.project_id
  region          = local.region
  resource_prefix = var.resource_prefix
}

module "filestore" {
  source = "github.com/GoogleCloudPlatform/hpc-toolkit//modules/file-system/filestore//?ref=v1.17.0"
  count  = length(var.filestore_new)

  deployment_name      = var.resource_prefix
  filestore_share_name = "nfsshare_${count.index}"
  filestore_tier       = var.filestore_new[count.index].filestore_tier
  local_mount          = var.filestore_new[count.index].local_mount
  network_id           = module.network.network_id
  project_id           = var.project_id
  region               = local.region
  size_gb              = var.filestore_new[count.index].size_gb
  zone                 = var.zone
  labels               = merge(var.labels, { ghpc_role = "file-system" })
}

module "cloudinit" {
  source = "./cloudinit"

  container = var.container
  filestores = [
    for n in module.filestore[*].network_storage
    : {
      local_mount  = n.local_mount
      remote_mount = "${n.server_ip}:${n.remote_mount}"
    }
  ]
  gcsfuses = var.gcsfuse_existing != null ? var.gcsfuse_existing : []
  machine_has_gpu = var.guest_accelerator != null || contains(
    ["a2", "a3", "g2"],
    split("-", var.machine_type)[0],
  )
}

module "compute_instance_template" {
  source = "../../common/instance_template"

  disk_size_gb          = var.disk_size_gb
  disk_type             = var.disk_type
  guest_accelerator     = var.guest_accelerator
  machine_image         = local.machine_image
  machine_type          = var.machine_type
  metadata              = { user-data = module.cloudinit.user-data }
  project_id            = var.project_id
  region                = local.region
  resource_prefix       = var.resource_prefix
  service_account       = var.service_account
  startup_script        = null
  subnetwork_self_links = module.network.subnetwork_self_links
  network_self_links    = module.network.network_self_links
  labels                = merge(var.labels, { ghpc_role = "compute" })
}

resource "google_compute_instance_group_manager" "mig" {
  provider = google-beta

  base_instance_name = "${var.resource_prefix}-vm"
  name               = "${var.resource_prefix}-mig"
  project            = var.project_id
  target_size        = var.target_size
  wait_for_instances = true
  zone               = var.zone

  update_policy {
    minimal_action        = "RESTART"
    max_unavailable_fixed = 1
    type                  = "OPPORTUNISTIC"
    replacement_method    = "RECREATE" # Instance name will be preserved
  }

  version {
    name              = "default"
    instance_template = module.compute_instance_template.id
  }

  timeouts {
    create = "30m"
    update = "30m"
  }
}
