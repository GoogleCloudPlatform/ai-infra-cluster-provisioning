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

| Name | Source | Version |
|------|--------|---------|
| <a name="module_dashboard"></a> [dashboard](#module\_dashboard) | ../../common/dashboard | n/a |
| <a name="module_kubernetes-operations"></a> [kubernetes-operations](#module\_kubernetes-operations) | ./kubernetes-operations | n/a |
| <a name="module_network"></a> [network](#module\_network) | ../../common/network | n/a |

## Resources

| Name | Type |
|------|------|
| [google-beta_google_container_cluster.gke-cluster](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_container_cluster) | resource |
| [google-beta_google_container_node_pool.gke-node-pools](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_container_node_pool) | resource |
| [google_project_iam_member.node_service_account_logWriter](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.node_service_account_metricWriter](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.node_service_account_monitoringViewer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |
| [google_compute_default_service_account.account](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_default_service_account) | data source |
| [google_container_engine_versions.gkeversion](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/container_engine_versions) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_disk_size_gb"></a> [disk\_size\_gb](#input\_disk\_size\_gb) | Size of the disk attached to each node, specified in GB. The smallest allowed disk size is 10GB. Defaults to 200GB.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#disk_size_gb), [gcloud](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create#--disk-size). | `number` | `200` | no |
| <a name="input_disk_type"></a> [disk\_type](#input\_disk\_type) | Type of the disk attached to each node. The default disk type is 'pd-standard'<br><br>Possible values: `["pd-ssd", "local-ssd", "pd-balanced", "pd-standard"]`<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#disk_type), [gcloud](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create#--disk-type). | `string` | `"pd-standard"` | no |
| <a name="input_enable_gke_dashboard"></a> [enable\_gke\_dashboard](#input\_enable\_gke\_dashboard) | Flag to enable GPU usage dashboards for the GKE cluster. | `bool` | `true` | no |
| <a name="input_gke_version"></a> [gke\_version](#input\_gke\_version) | The GKE version to be used as the minimum version of the master. The default value for that is latest master version.<br>More details can be found [here](https://cloud.google.com/kubernetes-engine/versioning#specifying_cluster_version)<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#name), [gcloud](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create#--name). | `string` | `null` | no |
| <a name="input_kubernetes_setup_config"></a> [kubernetes\_setup\_config](#input\_kubernetes\_setup\_config) | The configuration for setting up Kubernetes after GKE cluster is created.<pre>enable_kubernetes_setup: Flag to enable kubernetes setup. Default value is `true`.<br>kubernetes_service_account_name: The KSA (kubernetes service account) name to be used for Pods. Default value is `aiinfra-gke-sa`.<br>kubernetes_service_account_namespace: The KSA (kubernetes service account) namespace to be used for Pods. Default value is `default`.</pre>Related Docs: [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity) | <pre>object({<br>    enable_kubernetes_setup              = bool,<br>    kubernetes_service_account_name      = string,<br>    kubernetes_service_account_namespace = string<br>  })</pre> | `null` | no |
| <a name="input_network_config"></a> [network\_config](#input\_network\_config) | The network configuration to specify the type of VPC to be used.<br><br>Possible values: `["default", "new_multi_nic", "new_single_nic"]` | `string` | `"default"` | no |
| <a name="input_node_pools"></a> [node\_pools](#input\_node\_pools) | The list of node pools for the GKE cluster.<pre>zone: The zone in which the node pool's nodes should be located. Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool.html#node_locations)<br>node_count: The number of nodes per node pool. This field can be used to update the number of nodes per node pool. Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool.html#node_count)<br>machine_type: The name of a Google Compute Engine machine type. Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#machine_type)<br>guest_accelerator: This block is to provide information about GPUs. Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#nested_guest_accelerator)<br>This must be `null` when `machine_type` is of an [accelerator-optimized machine family](https://cloud.google.com/compute/docs/accelerator-optimized-machines)<br>    guest_accelerator.type: The accelerator type resource to expose to this instance.<br>    guest_accelerator.count: The number of the guest accelerator cards exposed to this instance.<br>enable_compact_placement: Specifies a custom placement policy for the nodes. Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool.html#placement_policy)</pre> | <pre>list(object({<br>    zone         = string,<br>    node_count   = number,<br>    machine_type = string,<br>    guest_accelerator = object({<br>      type  = string,<br>      count = number<br>    })<br>    enable_compact_placement = bool<br>  }))</pre> | n/a | yes |
| <a name="input_node_service_account"></a> [node\_service\_account](#input\_node\_service\_account) | The service account to be used by the Node VMs. If not specified, the "default" service account is used.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#nested_node_config), [gcloud](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create#--service-account). | `string` | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP Project ID to which the cluster will be deployed. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region in which the cluster master will be created. The cluster will be a regional cluster with multiple masters spread across zones in the region, and with default node locations in those zones as well. | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Arbitrary string with which all names of newly created resources will be prefixed. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | Google Kubernetes cluster id |
| <a name="output_name"></a> [name](#output\_name) | Google Kubernetes cluster name |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->