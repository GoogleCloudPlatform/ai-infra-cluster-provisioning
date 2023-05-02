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
  project_id   = "test-project-gke"
  region       = "us-central1"
  zone         = "us-central1-a"
  disk_size_gb = 2000
  name_prefix     = "aiinfra-gke-test"
  deployment_name = "aiinfra-gke-test-dpl"  
  metadata = {
    meta1 = "val"
    meta2 = "val2"
  }
  network_config               = "default_network"
  disk_type                    = "pd-ssd"
  gcs_bucket_path              = "gs://test-bucket/test-dir"
  labels = {
    ghpc_blueprint  = "aiinfra-gke"
    ghpc_deployment = "aiinfra-gke-test-dpl"
    label1          = "marker1"
  }
  orchestrator_type   = "gke"
  custom_node_pool = [
    {
      name = "test-pool-1"
      zone = "us-central1-a"
      node_count = 1
      machine_type = "n1-standard-1"
      guest_accelerator_count = 0
      guest_accelerator_type = "nvidia-tesla-a100"
      enable_compact_placement = false
    },
    {
      name = "test-pool-2"
      zone = "us-central1-c"
      node_count = 1
      machine_type = "n1-standard-1"
      guest_accelerator_count = 0
      guest_accelerator_type = "nvidia-tesla-a100"
      enable_compact_placement = false
    }
  ]
  
  kubernetes_setup_config = {
    enable_k8s_setup                     = true
    kubernetes_service_account_name      = "my-test-sa"
    kubernetes_service_account_namespace = "default"
    node_service_account                 = "xxxxxx-compute@developer.gserviceaccount.com"
  }
}

module "aiinfra-cluster" {
  source                       = "github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning//aiinfra-cluster"
  name_prefix                  = local.name_prefix
  zone                         = local.zone
  disk_type                    = local.disk_type
  gcs_bucket_path              = local.gcs_bucket_path
  orchestrator_type            = local.orchestrator_type
  custom_node_pool             = local.custom_node_pool
  kubernetes_setup_config      = local.kubernetes_setup_config
  network_config               = local.network_config
  labels                       = local.labels
  disk_size_gb                 = local.disk_size_gb
  region                       = local.region
  project_id                   = local.project_id
  deployment_name              = local.deployment_name
  metadata                     = local.metadata
}

