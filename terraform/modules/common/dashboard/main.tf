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
  gce_gke_gpu_utilization_data = try(
    jsondecode(tostring(data.http.gce-gke-gpu-utilization[0].response_body)),
    null,
  )
  nvidia_dcgm_data = try(
    jsondecode(tostring(data.http.nvidia-dcgm[0].response_body)),
    null,
  )
  nvidia_nvml_data = try(
    jsondecode(tostring(data.http.nvidia-nvml[0].response_body)),
    null,
  )

  widgets = concat(
    try(
      [
        for tile in local.gce_gke_gpu_utilization_data.mosaicLayout.tiles
        : jsonencode(tile.widget)
      ],
      [],
    ),
    try(
      [
        for tile in local.nvidia_dcgm_data.mosaicLayout.tiles
        : jsonencode(tile.widget)
      ],
      [],
    ),
    try(
      [
        for tile in local.nvidia_nvml_data.mosaicLayout.tiles
        : jsonencode(tile.widget)
      ],
      [],
    ),
  )
}

data "http" "gce-gke-gpu-utilization" {
  url   = "https://cloud-monitoring-dashboards.googleusercontent.com/samples/nvidia-gpu/gce-gke-gpu-utilization.json"
  count = var.enable_gce_gke_gpu_utilization_widgets ? 1 : 0

  request_headers = {
    Accept = "application/json"
  }
}

data "http" "nvidia-dcgm" {
  url   = "https://cloud-monitoring-dashboards.googleusercontent.com/samples/nvidia-gpu/nvidia-dcgm.json"
  count = var.enable_nvidia_dcgm_widgets ? 1 : 0

  request_headers = {
    Accept = "application/json"
  }
}

data "http" "nvidia-nvml" {
  url   = "https://cloud-monitoring-dashboards.googleusercontent.com/samples/nvidia-gpu/nvidia-nvml.json"
  count = var.enable_nvidia_nvml_widgets ? 1 : 0

  request_headers = {
    Accept = "application/json"
  }
}

module "dashboard" {
  source = "github.com/GoogleCloudPlatform/hpc-toolkit//modules/monitoring/dashboard/?ref=v1.17.0"

  base_dashboard  = "Empty"
  deployment_name = var.resource_prefix
  project_id      = var.project_id
  title           = "AI Accelerator Experience Dashboard"
  widgets         = local.widgets
}
