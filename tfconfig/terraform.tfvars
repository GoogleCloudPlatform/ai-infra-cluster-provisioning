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

name_prefix     = "sptf"
gpu_per_vm      = 2
service_account = "455207029971-compute@developer.gserviceaccount.com"
project_id      = "supercomputer-testing"
instance_count  = 1
zone            = "us-central1-f"
machine_type    = "a2-highgpu-2g"
instance_image = {
  family  = "pytorch-1-12-gpu-debian-10"
  project = "ml-images"
}
labels = {}
deployment_name = "sp-tf-v1"
region          = "us-central1"
