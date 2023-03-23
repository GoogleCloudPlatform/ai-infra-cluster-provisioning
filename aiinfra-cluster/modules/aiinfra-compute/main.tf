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
  startup_script = var.startup_script != null ? (
  { startup-script = var.startup_script }) : {}
  network_storage = var.network_storage != null ? (
  { network_storage = jsonencode(var.network_storage) }) : {}

  resource_prefix = var.name_prefix != null ? var.name_prefix : var.deployment_name

  is_gvnic_supported = ((var.instance_image.name != null && length(regexall("debian-11", var.instance_image.name)) > 0) || 
                        (var.instance_image.family != null && length(regexall("debian-11", var.instance_image.family)) > 0) || 
                        (var.instance_image.name != null && length(regexall("ubuntu", var.instance_image.name)) > 0) || 
                        (var.instance_image.family != null && length(regexall("ubuntu", var.instance_image.family)) > 0) || 
                        (var.instance_image.name != null && length(regexall("gvnic", var.instance_image.name)) > 0) || 
                        (var.instance_image.family != null && length(regexall("gvnic", var.instance_image.family)) > 0))

  enable_gvnic  = var.bandwidth_tier != "not_enabled" && local.is_gvnic_supported
  enable_tier_1 = var.bandwidth_tier == "tier_1_enabled"

  # use Spot provisioning model (now GA) over older preemptible model
  provisioning_model = var.spot ? "SPOT" : null

  # compact_placement : true when placement policy is provided and collocation set; false if unset
  compact_placement = try(var.placement_policy.collocation, null) != null

  gpu_attached = contains(["a2"], local.machine_family) || var.guest_accelerator != null

  # both of these must be false if either compact placement or preemptible/spot instances are used
  # automatic restart is tolerant of GPUs while on host maintenance is not
  automatic_restart           = local.compact_placement || var.spot ? false : null
  on_host_maintenance_default = local.compact_placement || var.spot || local.gpu_attached ? "TERMINATE" : "MIGRATE"

  on_host_maintenance = (
    var.on_host_maintenance != null
    ? var.on_host_maintenance
    : local.on_host_maintenance_default
  )

  oslogin_api_values = {
    "DISABLE" = "FALSE"
    "ENABLE"  = "TRUE"
  }
  enable_oslogin = var.enable_oslogin == "INHERIT" ? {} : { enable-oslogin = lookup(local.oslogin_api_values, var.enable_oslogin, "") }

  machine_vals            = split("-", var.machine_type)
  machine_family          = local.machine_vals[0]
  machine_not_shared_core = length(local.machine_vals) > 2
  machine_vcpus           = try(parseint(local.machine_vals[2], 10), 1)

  smt_capable_family = !contains(["t2d"], local.machine_family)
  smt_capable_vcpu   = local.machine_vcpus >= 2

  smt_capable          = local.smt_capable_family && local.smt_capable_vcpu && local.machine_not_shared_core
  set_threads_per_core = var.threads_per_core != null && (var.threads_per_core == 0 && local.smt_capable || try(var.threads_per_core >= 1, false))
  threads_per_core     = var.threads_per_core == 2 ? 2 : 1

  empty_access_config = {
    nat_ip                 = null,
    public_ptr_domain_name = null,
    network_tier           = null
  }

  default_network_interface = [{
    network            = var.network_self_link
    subnetwork         = var.subnetwork_self_link
    subnetwork_project = var.project_id
    network_ip         = null
    nic_type           = local.enable_gvnic ? "GVNIC" : null
    stack_type         = null
    queue_count        = null
    access_config      = var.disable_public_ips ? [] : [local.empty_access_config]
    ipv6_access_config = []
    alias_ip_range     = []
  }]

  network_interfaces = coalescelist(var.network_interfaces, local.default_network_interface)
}

data "google_compute_image" "compute_image" {
  name    = var.instance_image.name != "" ? var.instance_image.name : null
  family  = var.instance_image.family != "" ? var.instance_image.family : null
  project = var.instance_image.project
}

resource "google_compute_instance_template" "compute_vm_template" {
  project        = var.project_id
  provider       = google-beta
  count          = var.enable_gke ? 0 : 1
  name_prefix    = "${local.resource_prefix}"
  machine_type   = var.machine_type
  region         = var.region

  tags   = var.tags
  labels = var.labels

  disk {
    boot           = true
    source_image   = data.google_compute_image.compute_image.self_link
    disk_size_gb   = var.disk_size_gb
    disk_type      = var.disk_type
    labels         = var.labels
    auto_delete = true
  }

  dynamic "network_interface" {
    for_each = local.network_interfaces
    content {
      network            = network_interface.value.network
      subnetwork         = network_interface.value.subnetwork
      subnetwork_project = network_interface.value.subnetwork_project
      network_ip         = network_interface.value.network_ip
      nic_type           = network_interface.value.nic_type
      stack_type         = network_interface.value.stack_type
      queue_count        = network_interface.value.queue_count
      dynamic "access_config" {
        for_each = network_interface.value.access_config
        content {
          nat_ip                 = access_config.value.nat_ip
          network_tier           = access_config.value.network_tier
        }
      }
      dynamic "ipv6_access_config" {
        for_each = network_interface.value.ipv6_access_config
        content {
          network_tier           = ipv6_access_config.value.network_tier
        }
      }
      dynamic "alias_ip_range" {
        for_each = network_interface.value.alias_ip_range
        content {
          ip_cidr_range         = alias_ip_range.value.ip_cidr_range
          subnetwork_range_name = alias_ip_range.value.subnetwork_range_name
        }
      }
    }
  }

  network_performance_config {
    total_egress_bandwidth_tier = local.enable_tier_1 ? "TIER_1" : "DEFAULT"
  }

  dynamic "service_account" {
    for_each = var.service_account == null ? [] : [var.service_account]
    content {
      email  = lookup(service_account.value, "email", null)
      scopes = lookup(service_account.value, "scopes", null)
    }
  }

  guest_accelerator {
    type  = var.guest_accelerator.type
    count = var.guest_accelerator.count
  }

  scheduling {
    on_host_maintenance = local.on_host_maintenance
    automatic_restart   = local.automatic_restart
    preemptible         = var.spot
    provisioning_model  = local.provisioning_model
  }

  dynamic "advanced_machine_features" {
    for_each = local.set_threads_per_core ? [1] : []
    content {
      threads_per_core = local.threads_per_core
    }
  }

  metadata = merge(local.network_storage, local.startup_script, local.enable_oslogin, var.metadata)

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      metadata["ssh-keys"],
    ]
  }
}

resource "google_compute_instance_group_manager" "mig" {
  provider           = google-beta
  // Use Orchestrator_type flag to determine this.
  count = 0
  //count              = var.enable_gke ? 0 : 1
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
    instance_template = one(google_compute_instance_template.compute_vm_template[*].id)
  }
  target_size = var.instance_count
  depends_on = [var.network_self_link, var.network_storage]
  timeouts {
    create = "30m"
    update = "30m"
  }
}

module "aiinfra-slurm" {
  source                   = "../slurm-cluster"
  // Use Orchestrator_type flag to determine this.
  count                    = 1
  project_id               = var.project_id
  deployment_name          = var.deployment_name
  region                   = var.region
  zone                     = var.zone
  network_self_link        = var.network_self_link
  subnetwork_self_link     = var.subnetwork_self_link
  instance_template        = one(google_compute_instance_template.compute_vm_template[*].self_link)
}

module "aiinfra-gke" {
  source                   = "../gke-cluster"
  count                    = var.enable_gke ? 1 : 0
  project                  = var.project_id
  region                   = var.region
  zone                     = var.zone
  name                     = "${local.resource_prefix}-gke"
  gke_version              = var.gke_version
  disk_size_gb             = var.disk_size_gb
  disk_type                = var.disk_type
  network_self_link        = var.network_self_link
  subnetwork_self_link     = var.subnetwork_self_link
  node_service_account     = lookup(var.service_account, "email", null)
  node_pools               = var.node_pools
}