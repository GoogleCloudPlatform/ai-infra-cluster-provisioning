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
    enable_kubernetes_setup              = true
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
      "${path.module}/scripts/gke_cluster.sh create \
      ${self.triggers.cluster_name} \
      ${self.triggers.region}"
    EOT
    on_failure  = fail
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = "${path.module}/scripts/gke_cluster.sh destroy ${self.triggers.cluster_name} ${self.triggers.region}"
    on_failure  = fail
  }
}

resource "null_resource" "gke-node-pool-command" {
  for_each = {
    for idx, node_pool in var.node_pools : idx => node_pool
  }

  triggers = {
    cluster_name   = "${var.resource_prefix}-gke"
    region         = var.region
    node_pool_name = "${var.resource_prefix}-nodepool-${each.key}"
  }

  provisioner "local-exec" {
    when        = create
    interpreter = ["/bin/bash", "-c"]
    command     = "${path.module}/scripts/gke_node_pool.sh create ${self.triggers.cluster_name} ${self.triggers.node_pool_name} ${self.triggers.region}"
    on_failure  = fail
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = "${path.module}/scripts/gke_node_pool.sh destroy ${self.triggers.cluster_name} ${self.triggers.node_pool_name} ${self.triggers.region}"
    on_failure  = fail
  }

  depends_on = [null_resource.gke-cluster-command]
}