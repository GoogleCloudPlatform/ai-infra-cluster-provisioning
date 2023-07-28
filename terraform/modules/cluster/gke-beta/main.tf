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
  gke_master_version   = var.gke_version != null ? var.gke_version : data.google_container_engine_versions.gkeversion.latest_master_version
  node_service_account = var.node_service_account == null ? data.google_compute_default_service_account.account.email : var.node_service_account
  oauth_scopes = [
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/dataaccessauditlogging",
  ]

  kubernetes_setup_config = var.kubernetes_setup_config != null ? var.kubernetes_setup_config : {
    kubernetes_service_account_name      = "aiinfra-gke-sa"
    kubernetes_service_account_namespace = "default"
  }
}

data "google_compute_default_service_account" "account" {
  project = var.project_id
}

data "google_client_config" "current" {}

data "google_container_engine_versions" "gkeversion" {
  location = var.region
  project  = var.project_id
}

module "network" {
  source = "../../common/network"

  network_config  = "new_multi_nic"
  project_id      = var.project_id
  region          = var.region
  resource_prefix = var.resource_prefix
}

module "resource_policy" {
  source = "../../common/resource_policy"
  for_each = {
    for idx, node_pool in var.node_pools : idx => node_pool
  }
  project_id           = var.project_id
  resource_policy_name = "${var.resource_prefix}-policy-${each.key}"
  region               = var.region
}

resource "null_resource" "gke-cluster-command" {
  triggers = {
    project_id   = var.project_id
    cluster_name = "${var.resource_prefix}-gke"
    region       = var.region
    gke_version  = local.gke_master_version
  }

  provisioner "local-exec" {
    when        = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      ${path.module}/scripts/gke_cluster.sh create \
      ${self.triggers.project_id} \
      ${self.triggers.cluster_name} \
      ${self.triggers.region} \
      ${self.triggers.gke_version} 
    EOT
    on_failure  = fail
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      ${path.module}/scripts/gke_cluster.sh destroy \
      ${self.triggers.project_id} \
      ${self.triggers.cluster_name} \
      ${self.triggers.region} \
      ${self.triggers.gke_version} 
    EOT
    on_failure  = fail
  }

  depends_on = [module.resource_policy]
}

resource "null_resource" "gke-node-pool-command" {
  for_each = {
    for idx, node_pool in var.node_pools : idx => node_pool
  }

  triggers = {
    project_id      = var.project_id
    prefix          = var.resource_prefix
    cluster_name    = "${var.resource_prefix}-gke"
    node_pool_name  = "${var.resource_prefix}-nodepool-${each.key}"
    zone            = each.value.zone
    region          = var.region
    machine_type    = each.value.machine_type
    node_count      = each.value.node_count
    disk_type       = var.disk_type
    disk_size       = var.disk_size_gb
    resource_policy = "${var.resource_prefix}-policy-${each.key}"
  }

  provisioner "local-exec" {
    when        = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      ${path.module}/scripts/gke_node_pool.sh create \
      ${self.triggers.project_id} \
      ${self.triggers.cluster_name} \
      ${self.triggers.node_pool_name} \
      ${self.triggers.zone} \
      ${self.triggers.region} \
      ${self.triggers.machine_type} \
      ${self.triggers.node_count} \
      ${self.triggers.disk_type} \
      ${self.triggers.disk_size} \
      ${self.triggers.prefix} \
      ${self.triggers.resource_policy} 
    EOT
    on_failure  = fail
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      ${path.module}/scripts/gke_node_pool.sh destroy \
      ${self.triggers.project_id} \
      ${self.triggers.cluster_name} \
      ${self.triggers.node_pool_name} \
      ${self.triggers.zone} \
      ${self.triggers.region} \
      ${self.triggers.machine_type} \
      ${self.triggers.node_count} \
      ${self.triggers.disk_type} \
      ${self.triggers.disk_size} \
      ${self.triggers.prefix} \
      ${self.triggers.resource_policy} 
    EOT
    on_failure  = fail
  }

  depends_on = [null_resource.gke-cluster-command, module.network]
}

output "gke-cluster-name" {
  value = null_resource.gke-cluster-command.triggers.cluster_name
}

resource "google_project_iam_member" "node_service_account_logWriter" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${local.node_service_account}"
}

resource "google_project_iam_member" "node_service_account_metricWriter" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${local.node_service_account}"
}

resource "google_project_iam_member" "node_service_account_monitoringViewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${local.node_service_account}"
}

resource "null_resource" "kubernetes-setup-command" {
  triggers = {
    project_id    = var.project_id
    prefix        = var.resource_prefix
    gsa_name      = local.node_service_account
    ksa_name      = local.kubernetes_setup_config.kubernetes_service_account_name
    ksa_namespace = local.kubernetes_setup_config.kubernetes_service_account_namespace
  }

  provisioner "local-exec" {
    when        = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      ${path.module}/scripts/kubernetes-setup.sh \
      ${self.triggers.project_id} \
      ${self.triggers.gsa_name} \
      ${self.triggers.ksa_name} \
      ${self.triggers.ksa_namespace}
    EOT
    on_failure  = fail
  }

  depends_on = [null_resource.gke-cluster-command]
}