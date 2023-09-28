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
provider "helm" {
  kubernetes {
    host                   = var.gke_cluster_exists ? "https://${data.google_container_cluster.gke_cluster[0].endpoint}" : ""
    cluster_ca_certificate = var.gke_cluster_exists ? base64decode(data.google_container_cluster.gke_cluster[0].master_auth.0.cluster_ca_certificate) : ""
    token                  = data.google_client_config.default.access_token
  }
}

resource "helm_release" "kuberay" {
  count      = var.enable_ray ? 1 : 0
  name       = "kuberay"
  repository = "https://ray-project.github.io/kuberay-helm/"
  chart      = "kuberay-operator"
  version    = "1.0.0-rc.0"
}
