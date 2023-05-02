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

data "google_client_config" "current" {}

module "cluster" {
  source = "github.com/GoogleCloudPlatform/hpc-toolkit//community/modules/scheduler/gke-cluster//?ref=develop"

  project_id                    = var.project_id
  deployment_name               = var.deployment_name
  region                        = var.region
  network_id                    = var.network_id
  subnetwork_self_link          = var.subnetwork_self_link
  min_master_version            = var.min_master_version
  service_account               = var.service_account_email
  authenticator_security_groups = "gke-security-groups@google.com"
  labels                        = merge(var.labels, { ghpc_role = "scheduler" })

  timeouts {
    create = "120m"
    update = "120m"
  }
}

module "node-pools" {
  source = "github.com/GoogleCloudPlatform/hpc-toolkit//community/modules/compute/gke-node-pool//?ref=develop"

  for_each = {
    for node_pool in var.node_pools : node_pool.name => node_pool
  }

  project_id      = var.project_id
  cluster_id      = module.cluster.id
  service_account = var.service_account_email
  auto_upgrade    = false

  zones             = each.value.zones
  name              = each.value.name
  machine_type      = each.value.machine_type
  total_min_nodes   = each.value.node_count
  total_max_nodes   = each.value.node_count
  compact_placement = each.value.enable_compact_placement

  timeouts {
    create = "60m"
    update = "60m"
  }
}
