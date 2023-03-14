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

resource "google_monitoring_metric_descriptor" "nvlink_traffic_rate" {
  description  = "Rate of bytes sent from the GPU over NVLink over the sample period."
  display_name = "dcgm.gpu.nvlink_traffic_rate"
  labels { key = "gpu_number" }
  labels { key = "model" }
  labels { key = "uuid" }
  labels { key = "direction" }
  metric_kind = "GAUGE"
  value_type  = "INT64"
  type        = "workload.googleapis.com/dcgm.gpu.nvlink_traffic_rate"

  launch_stage = "BETA"
  metadata {
    sample_period = "60s"
    ingest_delay = "30s"
  }
}

resource "google_monitoring_metric_descriptor" "pcie_traffic_rate" {
  description  = "The average rate of bytes sent from the GPU over the PCIe bus over the sample period, including both protocol headers and data payloads."
  display_name = "dcgm.gpu.pcie_traffic_rate"
  labels { key = "gpu_number" }
  labels { key = "model" }
  labels { key = "uuid" }
  labels { key = "direction" }
  metric_kind = "GAUGE"
  value_type  = "INT64"
  unit        = "By/s"
  type        = "workload.googleapis.com/dcgm.gpu.pcie_traffic_rate"

  launch_stage = "BETA"
  metadata {
    sample_period = "60s"
    ingest_delay = "30s"
  }
}
