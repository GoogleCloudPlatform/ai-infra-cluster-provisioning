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
  compute_partitions = { for partition in var.compute_partitions : partition.name => {
    node_count_static = partition.node_count_static
    zone              = partition.zone

    disk_size_gb = coalesce(try(partition.disk_size_gb, null), 128)
    disk_type    = coalesce(try(partition.disk_type, null), "pd-standard")
    guest_accelerators = flatten([
      coalesce(try(partition.guest_accelerator, null), [])
    ])
    machine_type = coalesce(try(partition.machine_type, null), "a2-highgpu-2g")
    region       = join("-", slice(split("-", partition.zone), 0, 2))
    startup_runners = concat(
      alltrue([for e in [null, ""] : partition.startup_script != e]) ? [{
        type        = "shell"
        destination = "/tmp/startup_script.sh"
        content     = partition.startup_script
      }] : [],
      alltrue([for e in [null, ""] : partition.startup_script_file != e]) ? [{
        type        = "shell"
        destination = "/tmp/startup_script_file.sh"
        source      = partition.startup_script_file
      }] : [],
    )
  } }

  _zeroeth_partition_zone   = local.compute_partitions[var.compute_partitions[0].name]
  _zeroeth_partition_region = join("-", slice(split("-", local._zeroeth_partition_zone), 0, 2))

  controller_var = {
    disk_size_gb = coalesce(try(var.controller_var.disk_size_gb, null), 50)
    disk_type    = coalesce(try(var.controller_var.disk_type, null), "pd-ssd")
    machine_type = coalesce(try(var.controller_var.machine_type, null), "c2-standard-4")
    region = coalesce(
      try(join("-", slice(split("-", var.controller_var.zone), 0, 2)), null),
      _zeroeth_partition_region,
    )
    startup_runners = concat(
      alltrue([for e in [null, ""] : controller_var.startup_script != e]) ? [{
        type        = "shell"
        destination = "/tmp/startup_script.sh"
        content     = controller_var.startup_script
      }] : [],
      alltrue([for e in [null, ""] : controller_var.startup_script_file != e]) ? [{
        type        = "shell"
        destination = "/tmp/startup_script_file.sh"
        source      = controller_var.startup_script_file
      }] : [],
    )
    zone = coalesce(try(var.controller_var.zone, null), _zeroeth_partition_zone)
  }

  login_var = {
    disk_size_gb = coalesce(try(var.login_var.disk_size_gb, null), 50)
    disk_type    = coalesce(try(var.login_var.disk_type, null), "pd-standard")
    machine_type = coalesce(try(var.login_var.machine_type, null), "n2-standard-2")
    region = coalesce(
      try(join("-", slice(split("-", var.login_var.zone), 0, 2)), null),
      _zeroeth_partition_region,
    )
    startup_runners = concat(
      alltrue([for e in [null, ""] : login_var.startup_script != e]) ? [{
        type        = "shell"
        destination = "/tmp/startup_script.sh"
        content     = login_var.startup_script
      }] : [],
      alltrue([for e in [null, ""] : login_var.startup_script_file != e]) ? [{
        type        = "shell"
        destination = "/tmp/startup_script_file.sh"
        source      = login_var.startup_script_file
      }] : [],
    )
    zone = coalesce(try(var.login_var.zone, null), _zeroeth_partition_zone)
  }

  _instance_template_prefix = "https://www.googleapis.com/compute/beta/projects/${var.project_id}/global/instanceTemplates"

  compute_instance_templates = {
    for partition in var.compute_partitions
    : partition.name
    => "${local._instance_template_prefix}/${google_compute_instance_template.compute_instance_template[partition.name].name}"
  }
  controller_instance_template = "${local._instance_template_prefix}/${google_compute_instance_template.controller_instance_template.name}"
  login_instance_template      = "${local._instance_template_prefix}/${google_compute_instance_template.login_instance_template.name}"

}

module "network" {
  source = "../../common/network"

  network_config  = var.network_config
  project_id      = var.project_id
  region          = local.region
  resource_prefix = var.resource_prefix
}

module "gcsfuse" {
  source = "github.com/GoogleCloudPlatform/hpc-toolkit//modules/file-system/pre-existing-network-storage//?ref=v1.17.0"
  count  = length(var.gcsfuse_existing)

  fs_type       = "gcsfuse"
  local_mount   = var.gcsfuse_existing[count.index].local_mount
  mount_options = "defaults,_netdev,implicit_dirs,allow_other"
  remote_mount  = var.gcsfuse_existing[count.index].remote_mount
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
  labels               = { ghpc_role = "file-system" }
}

module "compute_startups" {
  source   = "github.com/GoogleCloudPlatform/hpc-toolkit//modules/scripts/startup-script/?ref=v1.17.0"
  for_each = toset(var.compute_partitions[*].partition_name)

  deployment_name = var.resource_prefix
  labels          = { ghpc_role = "scripts" }
  project_id      = var.project_id
  region          = local.region
  runners = concat(
    module.gcsfuse[*].client_install_runner,
    module.gcsfuse[*].mount_runner,
    module.filestore[*].install_nfs_client_runner,
    module.filestore[*].mount_runner,
    local.compute_partitions[each.key].startup_runners,
  )
}

module "controller_startup" {
  source = "github.com/GoogleCloudPlatform/hpc-toolkit//modules/scripts/startup-script/?ref=v1.17.0"

  deployment_name = var.resource_prefix
  labels          = { ghpc_role = "scripts" }
  project_id      = var.project_id
  region          = local.region
  runners = concat(
    module.gcsfuse[*].client_install_runner,
    module.gcsfuse[*].mount_runner,
    module.filestore[*].install_nfs_client_runner,
    module.filestore[*].mount_runner,
    local.controller_var.startup_runners,
  )
}

module "login_startup" {
  source = "github.com/GoogleCloudPlatform/hpc-toolkit//modules/scripts/startup-script/?ref=v1.17.0"

  deployment_name = var.resource_prefix
  labels          = { ghpc_role = "scripts" }
  project_id      = var.project_id
  region          = local.region
  runners = concat(
    module.gcsfuse[*].client_install_runner,
    module.gcsfuse[*].mount_runner,
    module.filestore[*].install_nfs_client_runner,
    module.filestore[*].mount_runner,
    local.login_var.startup_runners,
  )
}

module "compute_instance_templates" {
  source   = "../../common/instance_template"
  for_each = toset(var.compute_partitions[*].partition_name)

  disk_size_gb          = var.compute_partitions[each.key].disk_size_gb
  disk_type             = var.compute_partitions[each.key].disk_type
  guest_accelerator     = var.compute_partitions[each.key].guest_accelerator
  machine_image         = var.compute_partitions[each.key].machine_image
  machine_type          = var.compute_partitions[each.key].machine_type
  metadata              = null
  project_id            = var.project_id
  region                = local.region
  resource_prefix       = var.resource_prefix
  service_account       = var.service_account
  startup_script        = module.compute_startups[each.key].startup_script
  subnetwork_self_links = module.network.subnetwork_self_links
}

module "controller_instance_template" {
  source = "../../common/instance_template"

  disk_size_gb          = local.controller_var.disk_size_gb
  disk_type             = local.controller_var.disk_type
  guest_accelerator     = null
  machine_image         = local.machine_image
  machine_type          = local.controller_var.machine_type
  metadata              = null
  project_id            = var.project_id
  region                = local.region
  resource_prefix       = var.resource_prefix
  service_account       = var.service_account
  startup_script        = module.controller_startup.startup_script
  subnetwork_self_links = module.network.subnetwork_self_links
}

module "login_instance_template" {
  source = "../../common/instance_template"

  disk_size_gb          = local.login_var.disk_size_gb
  disk_type             = local.login_var.disk_type
  guest_accelerator     = null
  machine_image         = local.machine_image
  machine_type          = local.login_var.machine_type
  metadata              = null
  project_id            = var.project_id
  region                = local.region
  resource_prefix       = var.resource_prefix
  service_account       = var.service_account
  startup_script        = module.login_startup.startup_script
  subnetwork_self_links = module.network.subnetwork_self_links
}

module "node_groups" {
  source   = "github.com/GoogleCloudPlatform/hpc-toolkit//community/modules/compute/schedmd-slurm-gcp-v5-node-group//?ref=v1.17.0"
  for_each = toset(var.compute_partitions[*].partition_name)

  instance_template      = local.compute_instance_templates[each.key]
  labels                 = { ghpc_role = "compute" }
  name                   = each.key
  node_count_static      = local.compute_partitions[each.key].node_count_static
  node_count_dynamic_max = 0
  project_id             = var.project_id
}

module "partitions" {
  source   = "github.com/GoogleCloudPlatform/hpc-toolkit//community/modules/compute/schedmd-slurm-gcp-v5-partition//?ref=v1.17.0"
  for_each = toset(var.compute_partitions[*].partition_name)

  enable_placement = false
  deployment_name  = var.resource_prefix
  is_default       = each.key == var.compute_partitions[0].partition_name
  network_storage  = [] // flatten([var.network_storage])
  node_groups      = module.node_groups[each.key].node_groups
  partition_name   = local.compute_partitions[each.key].partition_name
  project_id       = var.project_id
  region           = local.compute_partitions[each.key].region
  //subnetwork_self_link = module.network.subnetwork_self_links[0]
  //subnetwork_project   = var.project_id
  zone = local.compute_partitions[each.key].zone
}

module "controller" {
  source = "github.com/GoogleCloudPlatform/hpc-toolkit//community/modules/scheduler/schedmd-slurm-gcp-v5-controller//?ref=v1.17.0"

  deployment_name      = var.resource_prefix
  instance_template    = var.controller_instance_template
  labels               = { ghpc_role = "scheduler" }
  network_storage      = [] // flatten([var.network_storage])
  partition            = flatten([module.partitions[*].partition])
  project_id           = var.project_id
  region               = local.controller_var.region
  service_account      = var.service_account
  subnetwork_self_link = module.network.subnetwork_self_links[0]
  //zone = local.controller_var.zone
}

module "login" {
  source = "github.com/GoogleCloudPlatform/hpc-toolkit//community/modules/scheduler/schedmd-slurm-gcp-v5-login//?ref=v1.17.0"

  controller_instance_id = module.controller.controller_instance_id
  deployment_name        = var.deployment_name
  instance_template      = var.login_instance_template
  labels                 = { ghpc_role = "scheduler" }
  network_self_link      = var.network_self_link
  project_id             = var.project_id
  region                 = var.region
  service_account        = var.service_account
  subnetwork_self_link   = module.network.subnetwork_self_links[0]
  //zone = var.zone
}
