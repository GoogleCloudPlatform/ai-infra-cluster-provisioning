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

module "compute_partition_node_group" {
  source                 = "github.com/GoogleCloudPlatform/hpc-toolkit//community/modules/compute/schedmd-slurm-gcp-v5-node-group//?ref=c1f4a44"
  instance_template      = var.instance_template
  node_count_static      = 2
  node_count_dynamic_max = 0
  project_id             = var.project_id
}

module "compute_partition" {
  source               = "github.com/GoogleCloudPlatform/hpc-toolkit//community/modules/compute/schedmd-slurm-gcp-v5-partition//?ref=c1f4a44"
  exclusive            = true
  deployment_name      = var.deployment_name
  project_id           = var.project_id
  # TODO: pass labels
  # labels               = merge(var.labels, { ghpc_role = "schedmd-slurm-gcp-v5-partition",})
  node_groups          = flatten([module.compute_partition_node_group.node_groups])
  enable_placement     = true
  subnetwork_self_link = var.subnetwork_self_link
  zone                 = var.zone
  # TODO: take list of GCS buckets and NFS filestore and provide it here.
  # network_storage      = flatten([module.datafs.network_storage, module.homefs.network_storage])
  region               = var.region
  partition_name       = "compute"
}

module "slurm_controller" {
  source     = "github.com/GoogleCloudPlatform/hpc-toolkit//community/modules/scheduler/schedmd-slurm-gcp-v5-controller//?ref=c1f4a44"
  project_id = var.project_id
  cloud_parameters = {
    resume_rate     = 0
    resume_timeout  = 1200
    suspend_rate    = 0
    suspend_timeout = 450
  }
  zone                            = var.zone
  region                          = var.region
  compute_startup_scripts_timeout = 0
  partition                       = flatten([module.compute_partition.partition])
  deployment_name                 = var.deployment_name
  # TODO: pass labels
  # labels                          = merge(var.labels, { ghpc_role = "schedmd-slurm-gcp-v5-controller",})
  network_self_link               = var.network_self_link
  # TODO: take list of GCS buckets and NFS filestore and provide it here.
  # network_storage                 = flatten([module.datafs.network_storage, module.homefs.network_storage])
  machine_type                    = "n2-standard-16"
  subnetwork_self_link            = var.subnetwork_self_link
}
