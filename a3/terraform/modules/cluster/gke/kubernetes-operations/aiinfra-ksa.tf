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
  installer_daemonsets = var.gke_cluster_exists ? {
    device_plugin = "https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/cmd/nvidia_gpu/device-plugin.yaml"
    nvidia_driver = "https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/nvidia-driver-installer/cos/daemonset-preloaded-latest.yaml"
    nccl_plugin   = "https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/gpudirect-tcpx/nccl-tcpx-installer.yaml"
  } : {}
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

data "http" "installer_daemonsets" {
  for_each = local.installer_daemonsets

  url = each.value
}

resource "kubectl_manifest" "installer_daemonsets" {
  for_each = local.installer_daemonsets

  yaml_body        = data.http.installer_daemonsets[each.key].response_body
  wait_for_rollout = false
}
