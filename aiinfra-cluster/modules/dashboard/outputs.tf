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
// https://github.com/GoogleCloudPlatform/monitoring-dashboard-samples/tree/master/dashboards/nvidia-gpu

output "widget_objects" {
  description = ""
  value = [
    {
      timeSeriesTable = {
        dataSets = [
          {
            timeSeriesQuery = {
              timeSeriesQueryLanguage = <<EOF
                fetch gce_instance
                | metric 'agent.googleapis.com/gpu/utilization'
                | map [Model: metric.model, UUID: metric.uuid, Instance: metadata.system.name, GPU: metric.gpu_number]
                | value cast_units(int_round(value.utilization), "%")
                EOF
            }
          },
        ]
        metricVisualization = "NUMBER"
      }
      title = "Observed GPU utilization per GPU (NVML reported)"
    },
    {
      timeSeriesTable = {
        dataSets = [
          {
            timeSeriesQuery = {
              timeSeriesQueryLanguage = <<EOF
                fetch gce_instance
                | metric 'agent.googleapis.com/gpu/utilization'
                | map [Model: metric.model, Instance: metadata.system.name, GPU: metric.gpu_number]
                | value [value.utilization: 1.0]
                | group_by [Model], [capacity: sum(value.utilization)]
                EOF
            }
          }
        ],
        metricVisualization = "NUMBER"
      },
      title = "Observed GPU Capacity"
    },
    {
      timeSeriesTable = {
        dataSets = [
          {
            timeSeriesQuery = {
              timeSeriesQueryLanguage = <<EOF
                fetch gce_instance
                | metric 'agent.googleapis.com/gpu/utilization'
                | map [Model: metric.model, Instance: metadata.system.name, GPU: metric.gpu_number]
                | group_by [Model], [capacity: sum(cast_units(value.utilization/100.0, "1"))]
                EOF
            }
          }
        ],
        metricVisualization = "NUMBER"
      },
      title = "Observed GPU Utilization (NVML reported)"
    },
    {
      timeSeriesTable = {
        columnSettings = [
          {
            column = "Name (from instance_id)",
            visible = true
          },
          {
            column = "zone",
            visible = true
          },
          {
            column = "instance_name",
            visible = true
          }
        ],
        dataSets = [
          {
            timeSeriesQuery = {
              timeSeriesQueryLanguage = <<EOF
                fetch gce_instance
                | metric 'agent.googleapis.com/gpu/processes/utilization'
                | map [Instance: metadata.system.name,
                    GPU: metric.gpu_number,
                    PID: metric.pid,
                    Owner: metric.owner,
                    Command: metric.command_line], 
                | value cast_units(int_round(value.utilization), "%")
                EOF
            }
          }
        ],
        metricVisualization = "NUMBER"
      },
      title = "Recently Observed GPU Processes - Lifetime GPU Utilization (NVML reported)"
    },
    {
      timeSeriesTable = {
        dataSets = [
          {
            timeSeriesQuery = {
              timeSeriesQueryLanguage = <<EOF
                fetch gce_instance
                | metric 'agent.googleapis.com/gpu/processes/max_bytes_used'
                | map [Instance: metadata.system.name,
                    GPU: metric.gpu_number,
                    PID: metric.pid,
                    Owner: metric.owner,
                    Command: metric.command_line]
                EOF
            }
          }
        ],
        metricVisualization = "NUMBER"
      },
      title = "Recently Observed GPU Processes - Lifetime Max GPU Memory Used (NVML reported)"
    },
    {
      title = "CPU Utilization (Hypervisor Reported)",
      xyChart = {
        chartOptions = {
          mode = "COLOR"
        },
        dataSets = [
          {
            plotType = "LINE",
            targetAxis = "Y1",
            timeSeriesQuery = {
              timeSeriesQueryLanguage = <<EOF
                fetch gce_instance
                | metric 'compute.googleapis.com/instance/cpu/utilization'
                | group_by 1m, [value_utilization_mean: mean(value.utilization)]
                | every 1m
                | group_by [metadata.system.name: metadata.system_labels.name],
                    [value_utilization_mean_mean: mean(value_utilization_mean)]
                EOF
            }
          }
        ],
        thresholds = [],
        timeshiftDuration = "0s",
        yAxis = {
          label = "y1Axis",
          scale = "LINEAR"
        }
      }
    },
    {
      title = "NIC Traffic Rate (OS reported)",
      xyChart = {
        chartOptions = {
          mode = "COLOR"
        },
        dataSets = [
          {
            legendTemplate = "$${metadata.system_labels\\.name} Device $${metric.labels.device} Direction $${metric.labels.direction} NIC ",
            minAlignmentPeriod = "60s",
            plotType = "LINE",
            targetAxis = "Y1",
            timeSeriesQuery = {
              apiSource = "DEFAULT_CLOUD",
              timeSeriesFilter = {
                aggregation = {
                  alignmentPeriod = "60s",
                  crossSeriesReducer = "REDUCE_NONE",
                  perSeriesAligner = "ALIGN_RATE"
                },
                filter = "metric.type=\"agent.googleapis.com/interface/traffic\" resource.type=\"gce_instance\" metric.label.\"device\"!=\"lo\" metric.label.\"device\"!=\"docker0\"",
                secondaryAggregation = {
                  alignmentPeriod = "60s",
                  crossSeriesReducer = "REDUCE_SUM",
                  groupByFields = [
                    "metric.label.\"device\"",
                    "metric.label.\"direction\"",
                    "metadata.system_labels.\"name\""
                  ],
                  perSeriesAligner = "ALIGN_NONE"
                }
              }
            }
          }
        ],
        thresholds = [],
        timeshiftDuration = "0s",
        yAxis = {
          label = "y1Axis",
          scale = "LINEAR"
        }
      }
    },
    {
      title = "GPU Utilization (NVML reported)",
      xyChart = {
        chartOptions = {
          mode = "COLOR"
        },
        dataSets = [
          {
            legendTemplate = "$${metadata.system_labels\\.name} GPU $${metric.labels.gpu_number} Non-Idle",
            minAlignmentPeriod = "60s",
            plotType = "LINE",
            targetAxis = "Y1",
            timeSeriesQuery = {
              apiSource = "DEFAULT_CLOUD",
              timeSeriesFilter = {
                aggregation = {
                  alignmentPeriod = "60s",
                  crossSeriesReducer = "REDUCE_MEAN",
                  groupByFields = [
                    "metric.label.\"gpu_number\"",
                    "metadata.system_labels.\"name\""
                  ],
                  perSeriesAligner = "ALIGN_MEAN"
                },
                filter = "metric.type=\"agent.googleapis.com/gpu/utilization\" resource.type=\"gce_instance\""
              }
            }
          }
        ],
        thresholds = [],
        timeshiftDuration = "0s",
        yAxis = {
          label = "y1Axis",
          scale = "LINEAR"
        }
      }
    },
    {
      title = "GPU Memory Usage (NVML reported)",
      xyChart = {
        chartOptions = {
          mode = "COLOR"
        },
        dataSets = [
          {
            legendTemplate = "$${metadata.system_labels\\.name} GPU $${metric.labels.gpu_number} $${metric.labels.memory_state}",
            minAlignmentPeriod = "60s",
            plotType = "LINE",
            targetAxis = "Y1",
            timeSeriesQuery = {
              apiSource = "DEFAULT_CLOUD",
              timeSeriesFilter = {
                aggregation = {
                  alignmentPeriod = "60s",
                  crossSeriesReducer = "REDUCE_SUM",
                  groupByFields = [
                    "metric.label.\"memory_state\"",
                    "metric.label.\"gpu_number\"",
                    "metadata.system_labels.\"name\""
                  ],
                  perSeriesAligner = "ALIGN_MEAN"
                },
                filter = "metric.type=\"agent.googleapis.com/gpu/memory/bytes_used\" resource.type=\"gce_instance\" metric.label.\"memory_state\"=\"used\""
              }
            }
          }
        ],
        thresholds = [],
        timeshiftDuration = "0s",
        yAxis = {
          label = "y1Axis",
          scale = "LINEAR"
        }
      }
    },
    {
      title = "SM Utilization and SM occupancy (DCGM reported)",
      xyChart = {
        chartOptions = {
          mode = "COLOR"
        },
        dataSets = [
          {
            legendTemplate = "$${metadata.system_labels\\.name} GPU $${metric.labels.gpu_number} SM utilization",
            minAlignmentPeriod = "60s",
            plotType = "LINE",
            targetAxis = "Y1",
            timeSeriesQuery = {
              apiSource = "DEFAULT_CLOUD",
              timeSeriesFilter = {
                aggregation = {
                  alignmentPeriod = "60s",
                  crossSeriesReducer = "REDUCE_SUM",
                  groupByFields = [
                    "metric.label.\"gpu_number\"",
                    "metadata.system_labels.\"name\""
                  ],
                  perSeriesAligner = "ALIGN_MEAN"
                },
                filter = "metric.type=\"workload.googleapis.com/dcgm.gpu.sm_utilization\" resource.type=\"gce_instance\""
              }
            }
          },
          {
            legendTemplate = "$${metadata.system_labels\\.name} GPU $${metric.labels.gpu_number} SM occpancy",
            minAlignmentPeriod = "60s",
            plotType = "LINE",
            targetAxis = "Y1",
            timeSeriesQuery = {
              apiSource = "DEFAULT_CLOUD",
              timeSeriesFilter = {
                aggregation = {
                  alignmentPeriod = "60s",
                  crossSeriesReducer = "REDUCE_SUM",
                  groupByFields = [
                    "metric.label.\"gpu_number\"",
                    "metadata.system_labels.\"name\""
                  ],
                  perSeriesAligner = "ALIGN_MEAN"
                },
                filter = "metric.type=\"workload.googleapis.com/dcgm.gpu.sm_occupancy\" resource.type=\"gce_instance\""
              }
            }
          }
        ],
        thresholds = [],
        timeshiftDuration = "0s",
        yAxis = {
          label = "y1Axis",
          scale = "LINEAR"
        }
      }
    },
    {
      title = "NVLink Traffic Rate (DCGM reported)",
      xyChart = {
        chartOptions = {
          mode = "COLOR"
        },
        dataSets = [
          {
            plotType = "LINE",
            targetAxis = "Y1",
            timeSeriesQuery = {
              timeSeriesQueryLanguage = <<EOF
                fetch gce_instance
                | metric 'workload.googleapis.com/dcgm.gpu.nvlink_traffic_rate'
                | group_by 1m, [value_nvlink_traffic_rate_mean: mean(cast_units(value.nvlink_traffic_rate, "By/s"))]
                | every 1m
                | group_by
                    [Instance: metadata.system_labels.name, GPU: metric.gpu_number, Direction: metric.direction,
                     ],
                    [value_nvlink_traffic_rate_mean_aggregate:
                       aggregate(value_nvlink_traffic_rate_mean)]
                EOF
            }
          }
        ],
        thresholds = [],
        timeshiftDuration = "0s",
        yAxis = {
          label = "y1Axis",
          scale = "LINEAR"
        }
      }
    },
    {
      title = "Pipe Utilization (DCGM reported)",
      xyChart = {
        chartOptions = {
          mode = "COLOR"
        },
        dataSets = [
          {
            legendTemplate = "$${metadata.system_labels\\.name} GPU $${metric.labels.gpu_number} Pipe $${metric.labels.pipe}",
            minAlignmentPeriod = "60s",
            plotType = "LINE",
            targetAxis = "Y1",
            timeSeriesQuery = {
              apiSource = "DEFAULT_CLOUD",
              timeSeriesFilter = {
                aggregation = {
                  alignmentPeriod = "60s",
                  crossSeriesReducer = "REDUCE_SUM",
                  groupByFields = [
                    "metric.label.\"pipe\"",
                    "metric.label.\"gpu_number\"",
                    "metadata.system_labels.\"name\""
                  ],
                  perSeriesAligner = "ALIGN_MEAN"
                },
                filter = "metric.type=\"workload.googleapis.com/dcgm.gpu.pipe_utilization\" resource.type=\"gce_instance\""
              }
            }
          }
        ],
        thresholds = [],
        timeshiftDuration = "0s",
        yAxis = {
          label = "y1Axis",
          scale = "LINEAR"
        }
      }
    },
    {
      title = "PCIe Traffic Rate (DCGM reported)",
      xyChart = {
        chartOptions = {
          mode = "COLOR"
        },
        dataSets = [
          {
            plotType = "LINE",
            targetAxis = "Y1",
            timeSeriesQuery = {
              timeSeriesQueryLanguage = <<EOF
                fetch gce_instance
                | metric 'workload.googleapis.com/dcgm.gpu.pcie_traffic_rate'
                | group_by 1m, [value_pcie_traffic_rate_mean: mean(cast_units(value.pcie_traffic_rate, "By/s"))]
                | every 1m
                | group_by
                    [Instance: metadata.system_labels.name, GPU: metric.gpu_number, Direction: metric.direction,
                     ],
                    [value_pcie_traffic_rate_mean_aggregate:
                       aggregate(value_pcie_traffic_rate_mean)]
                EOF
            }
          }
        ],
        thresholds = [],
        timeshiftDuration = "0s",
        yAxis = {
          label = "y1Axis",
          scale = "LINEAR"
        }
      }
    },
  ]
}
