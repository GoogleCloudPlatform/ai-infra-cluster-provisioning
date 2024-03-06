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
  metadata = merge(
    {
      user-data                    = module.cloudinit.user-data
      google-logging-use-fluentbit = "true"
      google-logging-enabled       = "true"
    },
    var.metadata != null ? var.metadata : {},
  )
}

module "network" {
  source = "../../common/network"

  nic0_existing   = var.network_existing
  project_id      = var.project_id
  region          = var.region
  resource_prefix = var.resource_prefix
}

module "filestore" {
  source = "github.com/GoogleCloudPlatform/hpc-toolkit//modules/file-system/filestore//?ref=v1.17.0"
  count  = length(var.filestore_new)

  deployment_name      = var.resource_prefix
  filestore_share_name = "nfsshare_${count.index}"
  filestore_tier       = var.filestore_new[count.index].filestore_tier
  local_mount          = var.filestore_new[count.index].local_mount
  network_id           = module.network.network_ids[0]
  project_id           = var.project_id
  region               = var.region
  size_gb              = var.filestore_new[count.index].size_gb
  zone                 = var.filestore_new[count.index].zone
  labels               = merge(var.labels, { ghpc_role = "file-system" })
}

module "cloudinit" {
  source = "./cloudinit"

  container          = var.container
  enable_install_gpu = var.enable_install_gpu
  filestores = [
    for n in module.filestore[*].network_storage
    : {
      local_mount  = n.local_mount
      remote_mount = "${n.server_ip}:${n.remote_mount}"
    }
  ]
  gcsfuses       = var.gcsfuse_existing != null ? var.gcsfuse_existing : []
  startup_script = var.startup_script
}

module "compute_instance_template" {
  source = "../../common/instance_template"
  count  = length(var.instance_groups)

  disk_size_gb                  = var.disk_size_gb
  disk_type                     = var.disk_type
  machine_image                 = var.machine_image
  machine_type                  = var.instance_groups[count.index].machine_type
  maintenance_interval          = var.maintenance_interval
  metadata                      = local.metadata
  project_id                    = var.project_id
  region                        = var.region
  resource_prefix               = var.resource_prefix
  service_account               = var.service_account
  use_compact_placement_policy  = var.use_compact_placement_policy
  existing_resource_policy_name = var.instance_groups[count.index].existing_resource_policy_name
  startup_script                = null
  subnetwork_self_links         = module.network.subnetwork_self_links
  network_self_links            = module.network.network_self_links
  labels                        = merge(var.labels, { ghpc_role = "compute" })
}

module "compute_instance_group_manager" {
  source = "../../common/instance_group_manager"
  count  = length(var.instance_groups)

  project_id           = var.project_id
  resource_prefix      = "${var.resource_prefix}-${count.index}"
  zone                 = var.instance_groups[count.index].zone
  instance_template_id = module.compute_instance_template[count.index].id
  target_size          = var.instance_groups[count.index].target_size
  wait_for_instances   = var.wait_for_instances
}
