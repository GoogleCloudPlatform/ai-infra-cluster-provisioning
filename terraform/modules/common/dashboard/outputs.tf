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

output "enable_gce_gke_gpu_utilization_widgets" { value = var.enable_gce_gke_gpu_utilization_widgets }
output "enable_nvidia_dcgm_widgets" { value = var.enable_nvidia_dcgm_widgets }
output "enable_nvidia_nvml_widgets" { value = var.enable_nvidia_nvml_widgets }
output "project_id" { value = var.project_id }
output "resource_prefix" { value = var.resource_prefix }

output "instructions" {
  description = "Instructions for accessing the dashboard"
  value       = module.dashboard.instructions
}
