<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
Copyright 2022 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_http"></a> [http](#provider\_http) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_dashboard"></a> [dashboard](#module\_dashboard) | github.com/GoogleCloudPlatform/hpc-toolkit//modules/monitoring/dashboard/ | v1.17.0 |

## Resources

| Name | Type |
|------|------|
| [http_http.gce-gke-gpu-utilization](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [http_http.nvidia-dcgm](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [http_http.nvidia-nvml](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_gce_gke_gpu_utilization_widgets"></a> [enable\_gce\_gke\_gpu\_utilization\_widgets](#input\_enable\_gce\_gke\_gpu\_utilization\_widgets) | Add GKE GPU utilization widgets to the dashboard. | `bool` | n/a | yes |
| <a name="input_enable_nvidia_dcgm_widgets"></a> [enable\_nvidia\_dcgm\_widgets](#input\_enable\_nvidia\_dcgm\_widgets) | Add Nvidia DCGM widgets to the dashboard. | `bool` | n/a | yes |
| <a name="input_enable_nvidia_nvml_widgets"></a> [enable\_nvidia\_nvml\_widgets](#input\_enable\_nvidia\_nvml\_widgets) | Add Nvidia NVML widgets to the dashboard. | `bool` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP Project ID to which the cluster will be deployed. | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Arbitrary string with which all names of newly created resources will be prefixed. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_instructions"></a> [instructions](#output\_instructions) | Instructions for accessing the dashboard |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->