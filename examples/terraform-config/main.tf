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
  network_config     = "default_network"
  disk_type          = "pd-ssd"
  machine_type       = "a2-highgpu-1g"
  instance_count     = 1
  region             = "us-central1"
  gcs_mount_list     = "spani-mount-test:/usr/trainfiles"
  gcs_bucket_path    = "gs://aiinfra-terraform-soumyapani-testing/spani5-deployment"
  deployment_name    = "sp-aiinfra-test-dpl"
  startup_command    = "echo \"Hello World\""
  project_id         = "soumyapani-testing"
  zone               = "us-central1-a"
  orchestrator_type  = "none"
  disk_size_gb       = 2000
  accelerator_type   = "nvidia-tesla-a100"
  nfs_filestore_list = ""
  instance_image = {
    family  = "pytorch-1-10-gpu-debian-10"
    name    = ""
    project = "ml-images"
  }
  metadata = {
    meta1 = "val"
    meta2 = "val2"
  }
  labels = {
    label1          = "marker1"
  }
  name_prefix = "sp-aiinfra-test"
  gpu_per_vm  = 1
}

module "aiinfra-cluster" {
  source             = "github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning//aiinfra-cluster//?ref=develop"
  region             = local.region
  instance_image     = local.instance_image
  gcs_mount_list     = local.gcs_mount_list
  nfs_filestore_list = local.nfs_filestore_list
  metadata           = local.metadata
  instance_count     = local.instance_count
  gpu_per_vm         = local.gpu_per_vm
  labels             = merge(local.labels, { ghpc_role = "aiinfra-cluster",})
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

