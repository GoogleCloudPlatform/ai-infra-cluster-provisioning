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
  machine_type = "a2-highgpu-1g"
  disk_size_gb = 2000
  gpu_per_vm   = 1
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
  gke_enable_compact_placement = false
  accelerator_type             = "nvidia-tesla-a100"
  instance_image = {
    family  = "tf-latest-gpu-gvnic-debian-10"
    name    = null
    project = "deeplearning-platform-release"
  }
  orchestrator_type   = "gke"
  gke_node_count_per_node_pool = 2
  gke_node_pool_count = 1
}

module "aiinfra-cluster" {
  source                       = "github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning//aiinfra-cluster"
  gke_node_pool_count          = local.gke_node_pool_count
  name_prefix                  = local.name_prefix
  zone                         = local.zone
  disk_type                    = local.disk_type
  instance_image               = local.instance_image
  accelerator_type             = local.accelerator_type
  gcs_bucket_path              = local.gcs_bucket_path
  machine_type                 = local.machine_type
  orchestrator_type            = local.orchestrator_type
  gke_enable_compact_placement = local.gke_enable_compact_placement
  network_config               = local.network_config
  labels                       = local.labels
  disk_size_gb                 = local.disk_size_gb
  region                       = local.region
  project_id                   = local.project_id
  deployment_name              = local.deployment_name
  gpu_per_vm                   = local.gpu_per_vm
  gke_node_count_per_node_pool = local.gke_node_count_per_node_pool
  metadata                     = local.metadata
}

