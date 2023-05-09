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

provider "kubernetes" {
    host                   = var.gke_conn.gke_cluster_endpoint
    cluster_ca_certificate = base64decode(var.gke_conn.gke_certificate_authority_data)
    token                  = var.gke_conn.gke_token
}

provider "kubectl" {
  host                   = var.gke_conn.gke_cluster_endpoint
  cluster_ca_certificate = base64decode(var.gke_conn.gke_certificate_authority_data)
  token                  = var.gke_conn.gke_token
  load_config_file       = false
}

// Binding KSA to google service account.
resource "google_service_account_iam_binding" "default-workload-identity" {
  count = var.enable_k8s_setup ? 1 : 0
  service_account_id = "projects/${var.project}/serviceAccounts/${var.node_service_account}"
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.project}.svc.id.goog[${var.kubernetes_service_account_namespace}/${var.kubernetes_service_account_name}]",
  ]
}

// Creating and Annotating KSA with google service account
resource "kubernetes_service_account" "gke-sa" {
  automount_service_account_token = false
  count = var.enable_k8s_setup ? 1 : 0
  metadata {
    name      = var.kubernetes_service_account_name
    namespace = var.kubernetes_service_account_namespace
    annotations = {
      "iam.gke.io/gcp-service-account" = var.node_service_account
    }
  }
}

// Installing NVIDIA GPU driver daemonset.
// ref: https://cloud.google.com/kubernetes-engine/docs/how-to/gpus#installing_drivers
data "http" "nvidia_driver_installer_manifest" {
  url = "https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/nvidia-driver-installer/cos/daemonset-preloaded.yaml"
}

resource "kubectl_manifest" "nvidia_driver_installer" {
  yaml_body = data.http.nvidia_driver_installer_manifest.body
}