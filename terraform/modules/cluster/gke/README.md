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
| <a name="provider_google"></a> [google](#provider\_google) | n/a |
| <a name="provider_google-beta"></a> [google-beta](#provider\_google-beta) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google-beta_google_container_cluster.gke-cluster](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_container_cluster) | resource |
| [google-beta_google_container_node_pool.gke-node-pools](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_container_node_pool) | resource |
| [google_project_iam_member.node_service_account_logWriter](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.node_service_account_metricWriter](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.node_service_account_monitoringViewer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |
| [google_container_engine_versions.gkeversion](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/container_engine_versions) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_disk_size_gb"></a> [disk\_size\_gb](#input\_disk\_size\_gb) | Size of disk for instances. | `number` | `200` | no |
| <a name="input_disk_type"></a> [disk\_type](#input\_disk\_type) | Disk type for instances. | `string` | `"pd-standard"` | no |
| <a name="input_enable_dataplane_v2"></a> [enable\_dataplane\_v2](#input\_enable\_dataplane\_v2) | Dataplane v2 provides better security, scalability, consistency and operations. | `bool` | `false` | no |
| <a name="input_gke_version"></a> [gke\_version](#input\_gke\_version) | The GKE version to use to create the cluster. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the cluster, unique within the project. | `string` | `"main"` | no |
| <a name="input_network_self_link"></a> [network\_self\_link](#input\_network\_self\_link) | The self link of the network to attach the VM. | `string` | `"default"` | no |
| <a name="input_node_locations"></a> [node\_locations](#input\_node\_locations) | Zones for a regional cluster, leave blank to auto select. | `list(string)` | `null` | no |
| <a name="input_node_pools"></a> [node\_pools](#input\_node\_pools) | The list of nodepools for the GKE cluster. | <pre>list(object({<br>    name                     = string<br>    zone                     = string<br>    node_count               = number<br>    machine_type             = string<br>    guest_accelerator_count  = number<br>    guest_accelerator_type   = string<br>    enable_compact_placement = bool<br>  }))</pre> | n/a | yes |
| <a name="input_node_service_account"></a> [node\_service\_account](#input\_node\_service\_account) | Email address of the service account to use for running nodes. | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Name of the project to use for instantiating clusters. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | GCP region where to create resources. | `string` | n/a | yes |
| <a name="input_scopes"></a> [scopes](#input\_scopes) | List of Oauth scopes to attach to node isntnaces in your GKE cluster. | `list(string)` | <pre>[<br>  "https://www.googleapis.com/auth/cloud-platform",<br>  "https://www.googleapis.com/auth/dataaccessauditlogging"<br>]</pre> | no |
| <a name="input_subnetwork_self_link"></a> [subnetwork\_self\_link](#input\_subnetwork\_self\_link) | The self link of the subnetwork to attach the VM. | `string` | `null` | no |
| <a name="input_zone"></a> [zone](#input\_zone) | GCP zone where to create resources. Only use if multi\_zonal is false. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gke_certificate_authority_data"></a> [gke\_certificate\_authority\_data](#output\_gke\_certificate\_authority\_data) | Kubernetes cluster cluster CA certificate |
| <a name="output_gke_cluster_endpoint"></a> [gke\_cluster\_endpoint](#output\_gke\_cluster\_endpoint) | Kubernetes cluster API endpoint |
| <a name="output_gke_cluster_id"></a> [gke\_cluster\_id](#output\_gke\_cluster\_id) | Google Kubernetes cluster id |
| <a name="output_gke_cluster_name"></a> [gke\_cluster\_name](#output\_gke\_cluster\_name) | Google Kubernetes cluster name |
| <a name="output_gke_token"></a> [gke\_token](#output\_gke\_token) | Kubernetes cluster access token |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->