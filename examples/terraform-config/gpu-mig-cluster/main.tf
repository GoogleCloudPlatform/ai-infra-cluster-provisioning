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
  project_id         = "test-project"
  name_prefix        = "aiinfra-gpu"
  deployment_name    = "aiinfra-gpu-dpl"
  region             = "us-central1"
  zone               = "us-central1-a"
  machine_type       = "a2-highgpu-1g"
  accelerator_type   = "nvidia-tesla-a100"
  instance_count     = 1
  gpu_per_vm  = 1
  network_config     = "default_network"
  disk_type          = "pd-ssd"
  disk_size_gb       = 2000
  instance_image = {
    family  = "pytorch-1-10-gpu-debian-10"
    name    = ""
    project = "ml-images"
  }
  gcs_bucket_path    = "gs://test-bucket/test-dir"
  orchestrator_type  = "none"
  startup_command    = "echo \"Hello World\""
  metadata = {
    meta1 = "val"
    meta2 = "val2"
  }
  labels = {
    label1          = "marker1"
  }
  nfs_filestore_list = ""
  gcs_mount_list     = "test-bucket:/usr/trainfiles"
}

module "aiinfra-cluster" {
  source             = "github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning//aiinfra-cluster"
  region             = local.region
  instance_image     = local.instance_image
  gcs_mount_list     = local.gcs_mount_list
  nfs_filestore_list = local.nfs_filestore_list
  metadata           = local.metadata
  instance_count     = local.instance_count
  gpu_per_vm         = local.gpu_per_vm
  labels             = local.labels
  accelerator_type   = local.accelerator_type
  orchestrator_type  = local.orchestrator_type
  disk_size_gb       = local.disk_size_gb
  startup_command    = local.startup_command
  machine_type       = local.machine_type
  zone               = local.zone
  name_prefix        = local.name_prefix
  deployment_name    = local.deployment_name
  disk_type          = local.disk_type
  project_id         = local.project_id
  network_config     = local.network_config
  gcs_bucket_path    = local.gcs_bucket_path
}

