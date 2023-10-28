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
  project  = var.project_id
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
