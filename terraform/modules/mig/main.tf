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
}

module "network" {
  source = "../network"

  network_config = var.network_config
  project_id = var.project_id
  region = local.region
  resource_prefix = var.resource_prefix
}

module "compute_instance_template" {
  source = "../instance_template"

  disk_size_gb = var.disk_size_gb
  disk_type = var.disk_type
  guest_accelerator = var.guest_accelerator
  machine_image = var.machine_image
  machine_type = var.machine_type
  metadata = null
  project_id = var.project_id
  region = local.region
  resource_prefix = var.resource_prefix
  service_account = var.service_account
  startup_script = var.startup_script
  subnetwork_self_links = module.network.subnetwork_self_links

  depends_on = [
    module.network,
  ]
}

resource "google_compute_instance_group_manager" "mig" {
  provider           = google-beta
  name               = "${local.resource_prefix}-mig"
  base_instance_name = "${local.resource_prefix}-vm"
  project            = var.project_id
  update_policy {
    minimal_action        = "RESTART"
    max_unavailable_fixed = 1
    type                  = "OPPORTUNISTIC"
    replacement_method    = "RECREATE" # Instance name will be preserved
  }
  zone               = var.zone
  wait_for_instances = true
  version {
    name              = "default"
    instance_template = google_compute_instance_template.templates.id
  }
  target_size = var.instance_count
  depends_on = [var.network_self_link, var.network_storage]
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
