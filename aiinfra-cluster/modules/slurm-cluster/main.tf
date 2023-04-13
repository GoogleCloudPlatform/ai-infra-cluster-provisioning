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

module "homefs" {
  source = "github.com/GoogleCloudPlatform/hpc-toolkit//modules/file-system/filestore//?ref=develop"

  project_id      = var.project_id
  deployment_name = var.deployment_name
  zone            = var.zone
  region          = var.region
  network_id      = var.network_id
  local_mount     = "/home"
  labels          = { ghpc_role = "file-system" }

  #size_gb              = var.filestore_size_gb
  #filestore_tier       = var.filestore_tier
}

module "compute_node_group" {
  source = "github.com/GoogleCloudPlatform/hpc-toolkit//community/modules/compute/schedmd-slurm-gcp-v5-node-group//?ref=develop"

  project_id             = var.project_id
  labels                 = { ghpc_role = "compute" }
  node_count_static      = var.node_count_static
  node_count_dynamic_max = var.node_count_dynamic_max
  instance_template      = var.instance_template_compute
}

module "compute_partition" {
  source = "github.com/GoogleCloudPlatform/hpc-toolkit//community/modules/compute/schedmd-slurm-gcp-v5-partition//?ref=develop"

  deployment_name      = var.deployment_name
  project_id           = var.project_id
  region               = var.region
  partition_name       = "compute"
  subnetwork_self_link = var.subnetwork_self_link
  network_storage      = flatten([module.homefs.network_storage])
  node_groups          = flatten([module.compute_node_group.node_groups])
  enable_placement     = false

  # TODO: pass labels
  # labels               = merge(var.labels, { ghpc_role = "schedmd-slurm-gcp-v5-partition",})
  # TODO: take list of GCS buckets and NFS filestore and provide it here.
  # network_storage      = flatten([module.datafs.network_storage, module.homefs.network_storage])
}

module "slurm_controller" {
  source = "github.com/GoogleCloudPlatform/hpc-toolkit//community/modules/scheduler/schedmd-slurm-gcp-v5-controller//?ref=develop"

  deployment_name      = var.deployment_name
  partition            = flatten([module.compute_partition.partition])
  project_id           = var.project_id
  region               = var.region
  zone                 = var.zone
  subnetwork_self_link = var.subnetwork_self_link
  network_self_link    = var.network_self_link
  network_storage      = flatten([module.homefs.network_storage])
  service_account      = var.service_account
  instance_template    = var.instance_template_controller
  labels               = { ghpc_role = "scheduler" }

  disable_controller_public_ips = false

  # TODO: pass labels
  # labels                          = merge(var.labels, { ghpc_role = "schedmd-slurm-gcp-v5-controller",})
  # TODO: take list of GCS buckets and NFS filestore and provide it here.
  # network_storage                 = flatten([module.datafs.network_storage, module.homefs.network_storage])
}

module "slurm_login" {
  source = "github.com/GoogleCloudPlatform/hpc-toolkit//community/modules/scheduler/schedmd-slurm-gcp-v5-login//?ref=develop"

  project_id             = var.project_id
  deployment_name        = var.deployment_name
  controller_instance_id = module.slurm_controller.controller_instance_id
  subnetwork_self_link   = var.subnetwork_self_link
  network_self_link      = var.network_self_link
  region                 = var.region
  zone                   = var.zone
  service_account        = var.service_account
  instance_template      = var.instance_template_login
  labels                 = { ghpc_role = "scheduler" }

  disable_login_public_ips = false
}
