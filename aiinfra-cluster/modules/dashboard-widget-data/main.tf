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
  dcgm_dashboard_data                    = jsondecode(tostring(data.http.nvidia_dcgm_dashboard.response_body))
  nvml_dashboard_data                    = jsondecode(tostring(data.http.nvidia_nvml_dashboard.response_body))
  gce_gke_gpu_utilization_dashboard_data = jsondecode(tostring(data.http.gce_gke_gpu_utilization_dashboard.response_body))

  nvidia_dcgm_widgets = [
    for tile in local.dcgm_dashboard_data.mosaicLayout.tiles : jsonencode(tile.widget)
  ]
  nvidia_nvml_widgets = [
    for tile in local.nvml_dashboard_data.mosaicLayout.tiles : jsonencode(tile.widget)
  ]
  gce_gke_gpu_utilization_widgets = [
    for tile in local.gce_gke_gpu_utilization_dashboard_data.mosaicLayout.tiles : jsonencode(tile.widget)
  ]
}

data "http" "nvidia_dcgm_dashboard" {
  url = "https://cloud-monitoring-dashboards.googleusercontent.com/samples/nvidia-gpu/nvidia-dcgm.json"

  request_headers = {
    Accept = "application/json"
  }
}

data "http" "nvidia_nvml_dashboard" {
  url = "https://cloud-monitoring-dashboards.googleusercontent.com/samples/nvidia-gpu/nvidia-nvml.json"

  request_headers = {
    Accept = "application/json"
  }
}

data "http" "gce_gke_gpu_utilization_dashboard" {
  url = "https://cloud-monitoring-dashboards.googleusercontent.com/samples/nvidia-gpu/gce-gke-gpu-utilization.json"

  request_headers = {
    Accept = "application/json"
  }
}
