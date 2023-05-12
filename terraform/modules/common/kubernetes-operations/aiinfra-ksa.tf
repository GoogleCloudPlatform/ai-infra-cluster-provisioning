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
  split_cluster_id = var.gke_cluster_exists ? split("/", var.cluster_id) : null
}

data "google_container_cluster" "gke_cluster" {
  count    = var.gke_cluster_exists ? 1 : 0
  name     = local.split_cluster_id[5]
  location = local.split_cluster_id[3]
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = var.gke_cluster_exists ? "https://${data.google_container_cluster.gke_cluster[0].endpoint}" : ""
  cluster_ca_certificate = var.gke_cluster_exists ? base64decode(data.google_container_cluster.gke_cluster[0].master_auth.0.cluster_ca_certificate) : ""
  token                  = data.google_client_config.default.access_token
}

provider "kubectl" {
  host                   = var.gke_cluster_exists ? "https://${data.google_container_cluster.gke_cluster[0].endpoint}" : ""
  cluster_ca_certificate = var.gke_cluster_exists ? base64decode(data.google_container_cluster.gke_cluster[0].master_auth.0.cluster_ca_certificate) : ""
  token                  = data.google_client_config.default.access_token
  load_config_file       = false
}

// Binding KSA to google service account.
resource "google_service_account_iam_binding" "default-workload-identity" {
  count              = var.setup_kubernetes_service_account != null && var.gke_cluster_exists ? 1 : 0
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.setup_kubernetes_service_account.google_service_account_name}"
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[${var.setup_kubernetes_service_account.kubernetes_service_account_namespace}/${var.setup_kubernetes_service_account.kubernetes_service_account_name}]",
  ]
}

// Creating and Annotating KSA with google service account
resource "kubernetes_service_account" "gke-sa" {
  automount_service_account_token = false
  count                           = var.setup_kubernetes_service_account != null && var.gke_cluster_exists ? 1 : 0
  metadata {
    name      = var.setup_kubernetes_service_account.kubernetes_service_account_name
    namespace = var.setup_kubernetes_service_account.kubernetes_service_account_namespace
    annotations = {
      "iam.gke.io/gcp-service-account" = var.setup_kubernetes_service_account.google_service_account_name
    }
  }
}

// Installing NVIDIA GPU driver daemonset.
// ref: https://cloud.google.com/kubernetes-engine/docs/how-to/gpus#installing_drivers
data "http" "nvidia_driver_installer_manifest" {
  url = "https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/nvidia-driver-installer/cos/daemonset-preloaded-latest.yaml"
}

resource "kubectl_manifest" "nvidia_driver_installer" {
  count     = var.install_nvidia_driver && var.gke_cluster_exists ? 1 : 0
  yaml_body = data.http.nvidia_driver_installer_manifest.response_body
}
