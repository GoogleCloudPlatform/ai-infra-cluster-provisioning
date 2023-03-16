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

// reference:
// https://github.com/GoogleCloudPlatform/opentelemetry-operations-collector/blob/master/receiver/dcgmreceiver/metadata.yaml

locals {
  attributes = {
    model = {
      key         = "model"
      description = "GPU model"
    }
    uuid = {
      key         = "uuid"
      description = "GPU universally unique identifier"
    }
    gpu_number = {
      key         = "gpu_number"
      description = "GPU index starting at 0"
    }
    memory_state = {
      key         = "memory_state"
      description = "GPU memory used or free"
    }
    pipe = {
      key         = "pipe"
      description = "GPU pipe in use, one of [tensor, fp64, fp32, fp16]"
    }
    direction = {
      key         = "direction"
      description = "Direction of the link traffic, one of [tx, rx]"
    }
  }
}

resource "google_monitoring_metric_descriptor" "sm_utilization" {
  display_name = "dcgm.gpu.sm_utilization"
  type         = "workload.googleapis.com/dcgm.gpu.sm_utilization"
  description  = "Fraction of time at least one warp was active on a multiprocessor, averaged over all multiprocessors."
  metric_kind  = "GAUGE"
  value_type   = "DOUBLE"
  unit         = "1"
  labels {
    key         = local.attributes.model.key
  }
  labels {
    key         = local.attributes.gpu_number.key
  }
  labels {
    key         = local.attributes.uuid.key
  }
  launch_stage = "BETA"
  metadata {
    sample_period = "60s"
    ingest_delay  = "30s"
  }
}

resource "google_monitoring_metric_descriptor" "sm_occupancy" {
  display_name = "dcgm.gpu.sm_occupancy"
  type         = "workload.googleapis.com/dcgm.gpu.sm_occupancy"
  description  = "Fraction of resident warps on a multiprocessor relative to the maximum number supported, averaged over time and all multiprocessors."
  metric_kind  = "GAUGE"
  value_type   = "DOUBLE"
  unit         = "1"
  labels {
    key         = local.attributes.model.key
  }
  labels {
    key         = local.attributes.gpu_number.key
  }
  labels {
    key         = local.attributes.uuid.key
  }
  launch_stage = "BETA"
  metadata {
    sample_period = "60s"
    ingest_delay  = "30s"
  }
}

resource "google_monitoring_metric_descriptor" "pipe_utilization" {
  display_name = "dcgm.gpu.pipe_utilization"
  type         = "workload.googleapis.com/dcgm.gpu.pipe_utilization"
  description  = "Fraction of cycles the corresponding GPU pipe was active, averaged over time and all multiprocessors."
  metric_kind  = "GAUGE"
  value_type   = "DOUBLE"
  unit         = "1"
  labels {
    key         = local.attributes.model.key
  }
  labels {
    key         = local.attributes.gpu_number.key
  }
  labels {
    key         = local.attributes.uuid.key
  }
  labels {
    key         = local.attributes.pipe.key
  }
  launch_stage = "BETA"
  metadata {
    sample_period = "60s"
    ingest_delay  = "30s"
  }
}

resource "google_monitoring_metric_descriptor" "dram_utilization" {
  display_name = "dcgm.gpu.dram_utilization"
  type         = "workload.googleapis.com/dcgm.gpu.dram_utilization"
  description  = "Fraction of cycles data was being sent or received from GPU memory."
  metric_kind  = "GAUGE"
  value_type   = "DOUBLE"
  unit         = "1"
  labels {
    key         = local.attributes.model.key
  }
  labels {
    key         = local.attributes.gpu_number.key
  }
  labels {
    key         = local.attributes.uuid.key
  }
  launch_stage = "BETA"
  metadata {
    sample_period = "60s"
    ingest_delay  = "30s"
  }
}

resource "google_monitoring_metric_descriptor" "pcie_traffic_rate" {
  display_name = "dcgm.gpu.pcie_traffic_rate"
  type         = "workload.googleapis.com/dcgm.gpu.pcie_traffic_rate"
  description  = "The average rate of bytes sent from the GPU over the PCIe bus over the sample period, including both protocol headers and data payloads."
  metric_kind  = "GAUGE"
  value_type   = "INT64"
  unit         = "By/s"
  labels {
    key         = local.attributes.model.key
  }
  labels {
    key         = local.attributes.gpu_number.key
  }
  labels {
    key         = local.attributes.uuid.key
  }
  labels {
    key         = local.attributes.direction.key
  }
  launch_stage = "BETA"
  metadata {
    sample_period = "60s"
    ingest_delay  = "30s"
  }
}

resource "google_monitoring_metric_descriptor" "nvlink_traffic_rate" {
  display_name = "dcgm.gpu.nvlink_traffic_rate"
  type         = "workload.googleapis.com/dcgm.gpu.nvlink_traffic_rate"
  description  = "The average rate of bytes received from the GPU over NVLink over the sample period, not including protocol headers."
  metric_kind  = "GAUGE"
  value_type   = "INT64"
  unit         = "By/s"
  labels {
    key         = local.attributes.model.key
  }
  labels {
    key         = local.attributes.gpu_number.key
  }
  labels {
    key         = local.attributes.uuid.key
  }
  labels {
    key         = local.attributes.direction.key
  }
  launch_stage = "BETA"
  metadata {
    sample_period = "60s"
    ingest_delay  = "30s"
  }
}

