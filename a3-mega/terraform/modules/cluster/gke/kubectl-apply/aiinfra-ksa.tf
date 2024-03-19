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
  split_cluster_id = split("/", var.cluster_id)
  kube_host = var.enable ? (
    "https://${data.google_container_cluster.gke_cluster[0].endpoint}"
  ) : ""
  kube_cert = var.enable ? base64decode(
    data.google_container_cluster.gke_cluster[0].master_auth.0.cluster_ca_certificate
  ) : ""
}

data "google_container_cluster" "gke_cluster" {
  count = var.enable ? 1 : 0

  project  = var.project_id
  name     = local.split_cluster_id[5]
  location = local.split_cluster_id[3]
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = local.kube_host
  cluster_ca_certificate = local.kube_cert
  token                  = data.google_client_config.default.access_token
}

provider "kubectl" {
  host                   = local.kube_host
  cluster_ca_certificate = local.kube_cert
  token                  = data.google_client_config.default.access_token
  load_config_file       = false
}

// Creating and Annotating KSA with google service account
resource "kubernetes_service_account" "ksa" {
  count = var.enable ? 1 : 0

  automount_service_account_token = false
  metadata {
    name      = var.ksa.name
    namespace = var.ksa.namespace
    annotations = {
      "iam.gke.io/gcp-service-account" = var.gcp_sa
    }
  }

  depends_on = [data.google_container_cluster.gke_cluster]
}

// Binding KSA to google service account.
resource "google_service_account_iam_binding" "default-workload-identity" {
  count = var.enable ? 1 : 0

  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.gcp_sa}"
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[${var.ksa.namespace}/${var.ksa.name}]",
  ]

  depends_on = [resource.kubernetes_service_account.ksa]
}

data "http" "installer_daemonsets" {
  for_each = var.enable ? var.daemonsets : {}

  url = each.value
}

resource "kubectl_manifest" "installer_daemonsets" {
  for_each = var.enable ? var.daemonsets : {}

  yaml_body        = data.http.installer_daemonsets[each.key].response_body
  wait_for_rollout = false

  depends_on = [resource.google_service_account_iam_binding.default-workload-identity]
}
