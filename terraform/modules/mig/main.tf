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

  startup_runners = concat(
    var.enable_ops_agent ? [{
      type        = "shell"
      destination = "/tmp/enable_cloud_ops_agent.sh"
      source      = "${path.module}/../../../install_scripts/install_cloud_ops_agent.sh"
    }] : [],
    var.enable_ray ? [{
      type        = "shell"
      destination = "/tmp/enable_ray.sh"
      source      = "${path.module}/../../../install_scripts/setup_ray.sh"
      args        = "1.12.1 26379 ${try(var.guest_accelerator.count, 0)}"
    }] : [],
    var.startup_script != null && var.startup_script != "" ? [{
      type        = "shell"
      destination = "/tmp/startup_script.sh"
      content     = var.startup_script
    }] : [],
    var.startup_script_file != null && var.startup_script_file != "" ? [{
      type        = "shell"
      destination = "/tmp/startup_script_file.sh"
      source      = var.startup_script_file
    }] : [],
  )

}

module "dashboard" {
  source = "../dashboard"
  count  = var.enable_ops_agent ? 1 : 0

  enable_gce_gke_gpu_utilization_widgets = true
  enable_nvidia_dcgm_widgets             = true
  enable_nvidia_nvml_widgets             = true
  project_id                             = var.project_id
  resource_prefix                        = var.resource_prefix
}

module "network" {
  source = "../network"

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

module "startup" {
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
    local.startup_runners,
  )
}

module "compute_instance_template" {
  source = "../instance_template"

  disk_size_gb          = var.disk_size_gb
  disk_type             = var.disk_type
  guest_accelerator     = var.guest_accelerator
  machine_image         = var.machine_image
  machine_type          = var.machine_type
  metadata              = null
  project_id            = var.project_id
  region                = local.region
  resource_prefix       = var.resource_prefix
  service_account       = var.service_account
  startup_script        = module.startup.startup_script
  subnetwork_self_links = module.network.subnetwork_self_links
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
    instance_template = module.compute_instance_template.resource_id
  }

  timeouts {
    create = "30m"
    update = "30m"
  }
}

//module "aiinfra-slurm" {
//  source     = "../slurm-cluster"
//  count      = var.orchestrator_type == "slurm" ? 1 : 0
//  depends_on = [
//    google_compute_instance_template.templates["compute"],
//    google_compute_instance_template.templates["controller"],
//    google_compute_instance_template.templates["login"],
//  ]
//
//  project_id           = var.project_id
//  deployment_name      = var.deployment_name
//  zone                 = var.zone
//  region               = var.region
//  network_self_link    = var.network_self_link
//  subnetwork_self_link = var.subnetwork_self_link
//  service_account      = var.service_account
//  network_storage      = var.slurm_network_storage
//
//  node_count_static      = var.slurm_node_count_static
//  node_count_dynamic_max = var.slurm_node_count_dynamic_max
//
//  instance_template_compute    = "${local.vm_template_self_link_prefix}/${google_compute_instance_template.templates["compute"].name}"
//  instance_template_controller = "${local.vm_template_self_link_prefix}/${google_compute_instance_template.templates["controller"].name}"
//  instance_template_login      = "${local.vm_template_self_link_prefix}/${google_compute_instance_template.templates["login"].name}"
//}
//
//module "aiinfra-gke" {
//  source                   = "../gke-cluster"
//  count                    = var.orchestrator_type == "gke" ? 1 : 0
//  project                  = var.project_id
//  region                   = var.region
//  zone                     = var.zone
//  name                     = "${local.resource_prefix}-gke"
//  gke_version              = var.gke_version
//  disk_size_gb             = var.disk_size_gb
//  disk_type                = var.disk_type
//  network_self_link        = var.network_self_link
//  subnetwork_self_link     = var.subnetwork_self_link
//  node_service_account     = var.service_account.email
//  node_pools               = var.node_pools
//}
//
//vm_template_self_link_prefix = "https://www.googleapis.com/compute/beta/projects/${var.project_id}/global/instanceTemplates"
//controller = {
//  machine_type            = "c2-standard-4"
//  disk_size_gb            = 50
//  disk_type               = "pd-ssd"
//  guest_accelerators = []
//}
//login = {
//  machine_type            = "n2-standard-2"
//  disk_size_gb            = 50
//  disk_type               = "pd-standard"
//  guest_accelerators = []
//}
