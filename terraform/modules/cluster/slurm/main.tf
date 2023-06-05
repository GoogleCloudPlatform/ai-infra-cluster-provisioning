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
  partition_names = var.compute_partitions[*].partition_name
  compute_partitions = {
    for partition in var.compute_partitions
    : partition.partition_name
    => {
      node_count_static = partition.node_count_static
      partition_name    = partition.partition_name
      zone              = partition.zone

      disk_size_gb      = coalesce(try(partition.disk_size_gb, null), 128)
      disk_type         = coalesce(try(partition.disk_type, null), "pd-standard")
      guest_accelerator = partition.guest_accelerator
      machine_image = coalesce(try(partition.machine_image, null), {
        project = "schedmd-slurm-public"
        family  = "schedmd-v5-slurm-22-05-8-ubuntu-2004-lts"
        name    = null
      })
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
    }
  }

  zeroeth_partition_name   = var.compute_partitions[0].partition_name
  zeroeth_partition_zone   = local.compute_partitions[local.zeroeth_partition_name].zone
  zeroeth_partition_region = join("-", slice(split("-", local.zeroeth_partition_zone), 0, 2))
  controller_var = {
    disk_size_gb = coalesce(try(var.controller_var.disk_size_gb, null), 50)
    disk_type    = coalesce(try(var.controller_var.disk_type, null), "pd-ssd")
    machine_image = coalesce(try(var.controller_var.machine_image, null), {
      project = "schedmd-slurm-public"
      family  = "schedmd-v5-slurm-22-05-8-ubuntu-2004-lts"
      name    = null
    })
    machine_type = coalesce(try(var.controller_var.machine_type, null), "c2-standard-4")
    region = coalesce(
      try(join("-", slice(split("-", var.controller_var.zone), 0, 2)), null),
      local.zeroeth_partition_region,
    )
    startup_runners = concat(
      alltrue([
        for e in [null, ""]
        : try(var.controller_var.startup_script != e, false)
        ]) ? [{
        type        = "shell"
        destination = "/tmp/startup_script.sh"
        content     = var.controller_var.startup_script
      }] : [],

      alltrue([
        for e in [null, ""]
        : try(var.controller_var.startup_script_file != e, false)
        ]) ? [{
        type        = "shell"
        destination = "/tmp/startup_script_file.sh"
        source      = var.controller_var.startup_script_file
      }] : [],
    )
    zone = coalesce(try(var.controller_var.zone, null), local.zeroeth_partition_zone)
  }
  login_var = {
    disk_size_gb = coalesce(try(var.login_var.disk_size_gb, null), 50)
    disk_type    = coalesce(try(var.login_var.disk_type, null), "pd-standard")
    machine_image = coalesce(try(var.login_var.machine_image, null), {
      project = "schedmd-slurm-public"
      family  = "schedmd-v5-slurm-22-05-8-ubuntu-2004-lts"
      name    = null
    })
    machine_type = coalesce(try(var.login_var.machine_type, null), "n2-standard-2")
    region = coalesce(
      try(join("-", slice(split("-", var.login_var.zone), 0, 2)), null),
      local.zeroeth_partition_region,
    )
    startup_runners = concat(
      alltrue([
        for e in [null, ""]
        : try(var.login_var.startup_script != e, false)
        ]) ? [{
        type        = "shell"
        destination = "/tmp/startup_script.sh"
        content     = var.login_var.startup_script
      }] : [],

      alltrue([
        for e in [null, ""]
        : try(var.login_var.startup_script_file != e, false)
        ]) ? [{
        type        = "shell"
        destination = "/tmp/startup_script_file.sh"
        source      = var.login_var.startup_script_file
      }] : [],
    )
    zone = coalesce(try(var.login_var.zone, null), local.zeroeth_partition_zone)
  }

  _instance_template_prefix = "https://www.googleapis.com/compute/beta/projects/${var.project_id}/global/instanceTemplates"
  compute_instance_templates = {
    for name in local.partition_names
    : name
    => "${local._instance_template_prefix}/${module.compute_instance_templates[name].name}"
  }
  controller_instance_template = "${local._instance_template_prefix}/${module.controller_instance_template.name}"
  login_instance_template      = "${local._instance_template_prefix}/${module.login_instance_template.name}"
}

module "network" {
  source = "../../common/network"

  network_config  = var.network_config
  project_id      = var.project_id
  region          = local.zeroeth_partition_region
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
  region               = local.zeroeth_partition_region
  size_gb              = var.filestore_new[count.index].size_gb
  zone                 = local.zeroeth_partition_zone
  labels               = merge(var.labels, { ghpc_role = "file-system" })

  depends_on = [
    module.network,
  ]
}

module "compute_startups" {
  source   = "github.com/GoogleCloudPlatform/hpc-toolkit//modules/scripts/startup-script/?ref=v1.17.0"
  for_each = toset(local.partition_names)

  deployment_name = var.resource_prefix
  labels          = merge(var.labels, { ghpc_role = "scripts" })
  project_id      = var.project_id
  region          = local.compute_partitions[each.key].region
  gcs_bucket_path = var.startup_script_gcs_bucket_path
  runners = concat(
    module.gcsfuse[*].client_install_runner,
    module.gcsfuse[*].mount_runner,
    module.filestore[*].install_nfs_client_runner,
    module.filestore[*].mount_runner,
    local.compute_partitions[each.key].startup_runners,
  )

  depends_on = [
    module.gcsfuse,
    module.filestore,
  ]
}

module "controller_startup" {
  source = "github.com/GoogleCloudPlatform/hpc-toolkit//modules/scripts/startup-script/?ref=v1.17.0"

  deployment_name = var.resource_prefix
  labels          = merge(var.labels, { ghpc_role = "scripts" })
  project_id      = var.project_id
  region          = local.controller_var.region
  gcs_bucket_path = var.startup_script_gcs_bucket_path
  runners = concat(
    module.gcsfuse[*].client_install_runner,
    module.gcsfuse[*].mount_runner,
    module.filestore[*].install_nfs_client_runner,
    module.filestore[*].mount_runner,
    local.controller_var.startup_runners,
  )

  depends_on = [
    module.gcsfuse,
    module.filestore,
  ]
}

module "login_startup" {
  source = "github.com/GoogleCloudPlatform/hpc-toolkit//modules/scripts/startup-script/?ref=v1.17.0"

  deployment_name = var.resource_prefix
  labels          = merge(var.labels, { ghpc_role = "scripts" })
  project_id      = var.project_id
  region          = local.login_var.region
  gcs_bucket_path = var.startup_script_gcs_bucket_path
  runners = concat(
    module.gcsfuse[*].client_install_runner,
    module.gcsfuse[*].mount_runner,
    module.filestore[*].install_nfs_client_runner,
    module.filestore[*].mount_runner,
    local.login_var.startup_runners,
  )

  depends_on = [
    module.gcsfuse,
    module.filestore,
  ]
}

module "compute_instance_templates" {
  source   = "../../common/instance_template"
  for_each = toset(local.partition_names)

  disk_size_gb          = local.compute_partitions[each.key].disk_size_gb
  disk_type             = local.compute_partitions[each.key].disk_type
  guest_accelerator     = local.compute_partitions[each.key].guest_accelerator
  labels                = var.labels
  machine_image         = local.compute_partitions[each.key].machine_image
  machine_type          = local.compute_partitions[each.key].machine_type
  metadata              = null
  project_id            = var.project_id
  region                = local.compute_partitions[each.key].region
  resource_prefix       = "${var.resource_prefix}-${each.key}"
  service_account       = var.service_account
  startup_script        = module.compute_startups[each.key].startup_script
  subnetwork_self_links = module.network.subnetwork_self_links
  network_self_links    = module.network.network_self_links

  depends_on = [
    module.network,
  ]
}

module "controller_instance_template" {
  source = "../../common/instance_template"

  disk_size_gb          = local.controller_var.disk_size_gb
  disk_type             = local.controller_var.disk_type
  guest_accelerator     = null
  labels                = var.labels
  machine_image         = local.controller_var.machine_image
  machine_type          = local.controller_var.machine_type
  metadata              = null
  project_id            = var.project_id
  region                = local.controller_var.region
  resource_prefix       = "${var.resource_prefix}-controller"
  service_account       = var.service_account
  startup_script        = module.controller_startup.startup_script
  subnetwork_self_links = module.network.subnetwork_self_links
  network_self_links    = module.network.network_self_links

  depends_on = [
    module.network,
  ]
}

module "login_instance_template" {
  source = "../../common/instance_template"

  disk_size_gb          = local.login_var.disk_size_gb
  disk_type             = local.login_var.disk_type
  guest_accelerator     = null
  labels                = var.labels
  machine_image         = local.login_var.machine_image
  machine_type          = local.login_var.machine_type
  metadata              = null
  project_id            = var.project_id
  region                = local.login_var.region
  resource_prefix       = "${var.resource_prefix}-login"
  service_account       = var.service_account
  startup_script        = null
  subnetwork_self_links = module.network.subnetwork_self_links
  network_self_links    = module.network.network_self_links

  depends_on = [
    module.network,
  ]
}

module "compute_node_groups" {
  source   = "github.com/GoogleCloudPlatform/hpc-toolkit//community/modules/compute/schedmd-slurm-gcp-v5-node-group//?ref=v1.17.0"
  for_each = toset(local.partition_names)

  instance_template      = local.compute_instance_templates[each.key]
  labels                 = merge(var.labels, { ghpc_role = "compute" })
  node_count_static      = local.compute_partitions[each.key].node_count_static
  node_count_dynamic_max = 0
  project_id             = var.project_id
  service_account        = module.compute_instance_templates[each.key].service_account
}

module "compute_partitions" {
  source   = "github.com/GoogleCloudPlatform/hpc-toolkit//community/modules/compute/schedmd-slurm-gcp-v5-partition//?ref=v1.17.0"
  for_each = toset(local.partition_names)

  enable_placement     = false
  deployment_name      = var.resource_prefix
  is_default           = each.key == local.partition_names[0]
  node_groups          = [module.compute_node_groups[each.key].node_groups]
  partition_name       = each.key
  project_id           = var.project_id
  region               = local.compute_partitions[each.key].region
  startup_script       = module.compute_startups[each.key].startup_script
  subnetwork_self_link = module.network.subnetwork_self_links[0]
  subnetwork_project   = var.project_id
  zone                 = local.compute_partitions[each.key].zone

  depends_on = [
    module.network,
  ]
}

module "controller" {
  source = "github.com/GoogleCloudPlatform/hpc-toolkit//community/modules/scheduler/schedmd-slurm-gcp-v5-controller//?ref=v1.17.0"

  deployment_name           = var.resource_prefix
  enable_cleanup_compute    = var.enable_cleanup_compute
  instance_template         = local.controller_instance_template
  labels                    = merge(var.labels, { ghpc_role = "scheduler" })
  partition                 = [for k in local.partition_names : module.compute_partitions[k].partition]
  project_id                = var.project_id
  region                    = local.controller_var.region
  service_account           = module.controller_instance_template.service_account
  controller_startup_script = module.controller_startup.startup_script
  subnetwork_self_link      = module.network.subnetwork_self_links[0]

  depends_on = [
    module.network,
  ]
}

module "login" {
  source = "github.com/GoogleCloudPlatform/hpc-toolkit//community/modules/scheduler/schedmd-slurm-gcp-v5-login//?ref=v1.17.0"

  controller_instance_id = module.controller.controller_instance_id
  deployment_name        = var.resource_prefix
  instance_template      = local.login_instance_template
  labels                 = merge(var.labels, { ghpc_role = "scheduler" })
  project_id             = var.project_id
  region                 = local.login_var.region
  service_account        = module.login_instance_template.service_account
  startup_script         = module.login_startup.startup_script
  subnetwork_self_link   = module.network.subnetwork_self_links[0]

  depends_on = [
    module.network,
  ]
}
