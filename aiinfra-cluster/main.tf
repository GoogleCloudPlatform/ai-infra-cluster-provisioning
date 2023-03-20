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
  depl_name = var.deployment_name != null ? var.deployment_name : "${var.name_prefix}-depl"

  default_metadata = merge(var.metadata, { VmDnsSetting = "ZonalPreferred", enable-oslogin = "TRUE", install-nvidia-driver = "True", })
  metadata = var.enable_notebook ? merge(local.default_metadata, { proxy-mode="project_editors", }) : local.default_metadata

  gcs_mount_arr         = compact(split(",", trimspace(var.gcs_mount_list)))
  nfs_filestore_arr     = compact(split(",", trimspace(var.nfs_filestore_list)))
  
  dir_copy_arr         = compact(split(",", trimspace(var.local_dir_copy_list)))
  dir_copy_setup       = flatten([
    for path in local.dir_copy_arr : [
      for file in fileset("${split(":", trimspace(path))[0]}", "**") : {
        "destination"   = "${split(":", trimspace(path))[1]}/${basename("${file}")}"
        "source"        = "${split(":", trimspace(path))[0]}/${basename("${file}")}"
        "type"          = "data" 
      }
    ]
  ])
  
  ray_setup             = var.orchestrator_type == "ray" ? [
    {
      "type"            = "shell"
      "destination"     = "/tmp/setup_ray.sh"
      "source"          = "${path.module}/installation_scripts/setup_ray.sh"
      "args"            = "1.12.1 26379 ${var.gpu_per_vm}"
    }
  ] : []

  startup_command_setup = var.startup_command != "" ? [
    {
      "type"            = "shell"
      "destination"     = "/tmp/initializestartup.sh"
      "content"         = "${var.startup_command}"
    }
  ] : []

  install_ops_agent = var.enable_ops_agent ? [
    {
      "type"        = "shell"
      "destination" = "install_cloud_ops_agent.sh"
      "source"      = "${path.module}/installation_scripts/install_cloud_ops_agent.sh"
    }
  ] : []
  
  vm_startup_setup      = concat(local.ray_setup, local.install_ops_agent, local.startup_command_setup)

}

module "aiinfra-network" {
  source          = "./modules/aiinfra-network"
  project_id      = var.project_id
  region          = var.region
  deployment_name = local.depl_name
  network_config  = var.network_config
}

module "gcsfuse_mount" {
  source        = "github.com/GoogleCloudPlatform/hpc-toolkit//modules/file-system/pre-existing-network-storage//?ref=c1f4a44"
  count         = length(local.gcs_mount_arr)
  fs_type       = "gcsfuse"
  mount_options = "defaults,_netdev,implicit_dirs,allow_other"
  remote_mount  = split(":", trimspace(local.gcs_mount_arr[count.index]))[0]
  local_mount   = split(":", trimspace(local.gcs_mount_arr[count.index]))[1]
}

module "nfs_filestore" {
  source          = "github.com/GoogleCloudPlatform/hpc-toolkit//modules/file-system/filestore//?ref=c1f4a44"
  count           = length(local.nfs_filestore_arr)
  project_id      = var.project_id
  region          = var.region
  zone            = var.zone
  deployment_name = local.depl_name
  network_name    = module.aiinfra-network.network_name
  filestore_share_name = "nfsshare_${count.index}"
  labels          = merge(var.labels, { ghpc_role = "aiinfra-filestore",})
  local_mount     = split(":", trimspace(local.nfs_filestore_arr[count.index]))[0]
  filestore_tier  = split(":", trimspace(local.nfs_filestore_arr[count.index]))[1]
  size_gb         = length(split(":", trimspace(local.nfs_filestore_arr[count.index]))) > 2 ? split(":", trimspace(local.nfs_filestore_arr[count.index]))[2] : 2560
  depends_on = [
    module.aiinfra-network
  ]
}

module "startup" {
  source          = "github.com/GoogleCloudPlatform/hpc-toolkit//modules/scripts/startup-script/?ref=1b1cdb09347433ecdb65488989f70135e65e217b"
  project_id      = var.project_id
  runners = concat(local.dir_copy_setup
  , module.gcsfuse_mount[*].client_install_runner
  , module.gcsfuse_mount[*].mount_runner
  , module.nfs_filestore[*].install_nfs_client_runner
  , module.nfs_filestore[*].mount_runner
  , local.vm_startup_setup)
  labels          = merge(var.labels, { ghpc_role = "scripts",})
  deployment_name = local.depl_name
  gcs_bucket_path = var.gcs_bucket_path
  region          = var.region
}

module "aiinfra-mig" {
  source               = "./modules/vm-instance-group"
  subnetwork_self_link = module.aiinfra-network.subnetwork_self_link
  service_account = {
    email  = var.service_account.email
    scopes = ["cloud-platform"]
  }
  instance_count    = var.instance_count
  project_id        = var.project_id
  disk_size_gb      = var.disk_size_gb
  disk_type         = var.disk_type
  network_self_link = module.aiinfra-network.network_self_link
  placement_policy = {
    availability_domain_count = null
    collocation               = "COLLOCATED"
    vm_count                  = var.instance_count
  }
  instance_image      = var.instance_image
  on_host_maintenance = "TERMINATE"
  machine_type        = var.machine_type
  zone                = var.zone
  region              = var.region
  startup_script      = module.startup.startup_script
  metadata = local.metadata
  labels      = merge(var.labels, { aiinfra_role = "compute",})
  name_prefix = var.name_prefix
  guest_accelerator = [{
    count = var.gpu_per_vm
    type  = var.accelerator_type
  }]
  deployment_name = local.depl_name
  network_interfaces = module.aiinfra-network.network_interfaces
  depends_on = [
    module.aiinfra-network
  ]
}

module "dashboard-metrics" {
  source               = "./modules/dashboard-metrics"
}

/*
* The dashboard needs to include GPU metrics from new ops agent.
*/
module "aiinfra-default-dashboard" {
  source          = "github.com/GoogleCloudPlatform/hpc-toolkit//modules/monitoring/dashboard/?ref=c1f4a44d92e775baa8c48aab6ae28cf9aee932a1"
  count           = var.enable_ops_agent ? 1 : 0
  project_id      = var.project_id
  deployment_name = local.depl_name
  base_dashboard  = "Empty"
  title           = "AI Accelerator Experience Dashboard"
  widgets         = [
    for widget_object in module.dashboard-metrics.widget_objects : jsonencode(widget_object)
  ]
  depends_on      = [module.dashboard-metrics]
}
