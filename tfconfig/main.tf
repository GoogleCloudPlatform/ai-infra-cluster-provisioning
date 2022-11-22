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

module "network1" {
  source     = "./modules/pre-existing-vpc"
  project_id = var.project_id
  region     = var.region
}

module "startup" {
  source     = "./modules/startup-script"
  project_id = var.project_id
  runners = [{
    destination = "install_cloud_ops_agent.sh"
    source      = "modules/startup-script/examples/install_cloud_ops_agent.sh"
    type        = "shell"
__REPLACE_FILES__
__REPLACE_STARTUP_SCRIPT__
  }]
  labels          = merge(var.labels, { ghpc_role = "scripts",})
  deployment_name = var.deployment_name
  gcs_path        = var.gcs_path
  gcs_bucket      = var.gcs_bucket
  region          = var.region
}

module "compute-vm-1" {
  source               = "./modules/vm-instance-group"
  subnetwork_self_link = module.network1.subnetwork_self_link
  service_account = {
    email  = var.service_account
    scopes = ["cloud-platform"]
  }
  instance_count    = var.instance_count
  project_id        = var.project_id
  disk_size_gb      = var.disk_size_gb
  disk_type         = var.disk_type
  network_self_link = module.network1.network_self_link
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
  metadata = merge(var.metadata, { VmDnsSetting = "ZonalPreferred", enable-oslogin = "TRUE", install-nvidia-driver = "True", proxy-mode="project_editors", })
  labels      = merge(var.labels, { aiinfra_role = "compute",})
  name_prefix = var.name_prefix
  guest_accelerator = [{
    count = var.gpu_per_vm
    type  = var.accelerator_type
  }]
  deployment_name = var.deployment_name
}

module "sp-compute-hpc-dash" {
  source          = "./modules/dashboard"
  project_id      = var.project_id
  deployment_name = var.deployment_name
  title           = "AI Accelerator Experience Dashboard"
}

