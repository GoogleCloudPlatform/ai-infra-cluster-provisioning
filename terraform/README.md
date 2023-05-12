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

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 3.83, < 5.0 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | >= 3.83, < 5.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 2.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 3.83, < 5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aiinfra-compute"></a> [aiinfra-compute](#module\_aiinfra-compute) | ./modules/aiinfra-compute | n/a |
| <a name="module_aiinfra-default-dashboard"></a> [aiinfra-default-dashboard](#module\_aiinfra-default-dashboard) | github.com/GoogleCloudPlatform/hpc-toolkit//modules/monitoring/dashboard/ | c1f4a44d92e775baa8c48aab6ae28cf9aee932a1 |
| <a name="module_aiinfra-k8s-setup"></a> [aiinfra-k8s-setup](#module\_aiinfra-k8s-setup) | ./modules/common/kubernetes-operations | n/a |
| <a name="module_aiinfra-network"></a> [aiinfra-network](#module\_aiinfra-network) | ./modules/aiinfra-network | n/a |
| <a name="module_dashboard-widget-data"></a> [dashboard-widget-data](#module\_dashboard-widget-data) | ./modules/dashboard-widget-data | n/a |
| <a name="module_gcsfuse_mount"></a> [gcsfuse\_mount](#module\_gcsfuse\_mount) | github.com/GoogleCloudPlatform/hpc-toolkit//modules/file-system/pre-existing-network-storage// | c1f4a44 |
| <a name="module_nfs_filestore"></a> [nfs\_filestore](#module\_nfs\_filestore) | github.com/GoogleCloudPlatform/hpc-toolkit//modules/file-system/filestore// | c1f4a44 |
| <a name="module_startup"></a> [startup](#module\_startup) | github.com/GoogleCloudPlatform/hpc-toolkit//modules/scripts/startup-script/ | 58ff5ad44b1b80a62c447eca4d57e9bba9badf70 |

## Resources

| Name | Type |
|------|------|
| [google_compute_default_service_account.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_default_service_account) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_accelerator_type"></a> [accelerator\_type](#input\_accelerator\_type) | The accelerator (GPU) type. | `string` | `"nvidia-tesla-a100"` | no |
| <a name="input_custom_node_pool"></a> [custom\_node\_pool](#input\_custom\_node\_pool) | The list of custom nodepools for the GKE cluster. | <pre>list(object({<br>    name                     = string<br>    zone                     = string<br>    node_count               = number<br>    machine_type             = string<br>    guest_accelerator_count  = number<br>    guest_accelerator_type   = string<br>    enable_compact_placement = bool<br>  }))</pre> | `[]` | no |
| <a name="input_deployment_name"></a> [deployment\_name](#input\_deployment\_name) | The deployment name. Default value is name\_prefix-depl. | `string` | `null` | no |
| <a name="input_disk_size_gb"></a> [disk\_size\_gb](#input\_disk\_size\_gb) | Size of disk for VM instances. | `number` | `1000` | no |
| <a name="input_disk_type"></a> [disk\_type](#input\_disk\_type) | Boot disk type, can be either pd-ssd, local-ssd, or pd-standard (default). | `string` | `"pd-standard"` | no |
| <a name="input_enable_notebook"></a> [enable\_notebook](#input\_enable\_notebook) | The flag to enable jupyter notebook initialization. | `bool` | `true` | no |
| <a name="input_enable_ops_agent"></a> [enable\_ops\_agent](#input\_enable\_ops\_agent) | The flag to enable Ops agent installation. | `bool` | `true` | no |
| <a name="input_gcs_bucket_path"></a> [gcs\_bucket\_path](#input\_gcs\_bucket\_path) | The GCS bucket path to use for startup scripts. | `string` | n/a | yes |
| <a name="input_gcs_mount_list"></a> [gcs\_mount\_list](#input\_gcs\_mount\_list) | Comma separate list of GCS buckets to be mounted in the VMs. | `string` | `""` | no |
| <a name="input_gke_enable_compact_placement"></a> [gke\_enable\_compact\_placement](#input\_gke\_enable\_compact\_placement) | The flag to enable compact placement for GKE node pools. | `bool` | `true` | no |
| <a name="input_gke_node_count_per_node_pool"></a> [gke\_node\_count\_per\_node\_pool](#input\_gke\_node\_count\_per\_node\_pool) | The desired node count per node pool for GKE cluster. Creation will fail if at least this number of Nodes cannot be created. | `number` | `0` | no |
| <a name="input_gke_node_pool_count"></a> [gke\_node\_pool\_count](#input\_gke\_node\_pool\_count) | The number of homogeneous node pools for GKE cluster. | `number` | `0` | no |
| <a name="input_gke_version"></a> [gke\_version](#input\_gke\_version) | The GKE version to use to create the cluster. | `string` | `null` | no |
| <a name="input_gpu_per_vm"></a> [gpu\_per\_vm](#input\_gpu\_per\_vm) | The number of GPUs per VM. | `number` | `0` | no |
| <a name="input_instance_count"></a> [instance\_count](#input\_instance\_count) | The number of VM instances. | `number` | `0` | no |
| <a name="input_instance_image"></a> [instance\_image](#input\_instance\_image) | The VM instance image. | <pre>object({<br>    name    = string,<br>    family  = string,<br>    project = string<br>  })</pre> | `null` | no |
| <a name="input_kubernetes_setup_config"></a> [kubernetes\_setup\_config](#input\_kubernetes\_setup\_config) | The configuration to setup GKE cluster. | <pre>object({<br>    enable_k8s_setup                     = bool<br>    kubernetes_service_account_name      = string<br>    kubernetes_service_account_namespace = string<br>    node_service_account                 = string<br>  })</pre> | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Lables for the GPU cluster resources. | `map(any)` | n/a | yes |
| <a name="input_local_dir_copy_list"></a> [local\_dir\_copy\_list](#input\_local\_dir\_copy\_list) | The comma separated list of local directories to copy and destination path on the VMs. E.G.: <local/dir/path>:<dest/path>, | `string` | `""` | no |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | The VM type to use for compute. | `string` | `"n1-standard-1"` | no |
| <a name="input_metadata"></a> [metadata](#input\_metadata) | Metadata for the VM instance. | `map(any)` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | The name prefix to be used for creating resources. | `string` | n/a | yes |
| <a name="input_network_config"></a> [network\_config](#input\_network\_config) | The network configuration to specify the type of VPC to be used, can be either default\_network (default), new\_network or multi\_nic\_network | `string` | `"default_network"` | no |
| <a name="input_nfs_filestore_list"></a> [nfs\_filestore\_list](#input\_nfs\_filestore\_list) | Comma separated list of NFS filestore paths to be created for the VMs. | `string` | `""` | no |
| <a name="input_orchestrator_type"></a> [orchestrator\_type](#input\_orchestrator\_type) | The job orchestrator to be used, can be either ray (default), slurm or gke. | `string` | `"none"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The project\_id to create the resources for GPU cluster. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region to create the GPU cluster. | `string` | n/a | yes |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account) | Service account to attach to the instance. See https://www.terraform.io/docs/providers/google/r/compute_instance_template.html#service_account. | <pre>object({<br>    email  = string,<br>    scopes = set(string)<br>  })</pre> | <pre>{<br>  "email": null,<br>  "scopes": [<br>    "https://www.googleapis.com/auth/devstorage.read_write",<br>    "https://www.googleapis.com/auth/logging.write",<br>    "https://www.googleapis.com/auth/monitoring.write",<br>    "https://www.googleapis.com/auth/servicecontrol",<br>    "https://www.googleapis.com/auth/service.management.readonly",<br>    "https://www.googleapis.com/auth/trace.append",<br>    "cloud-platform"<br>  ]<br>}</pre> | no |
| <a name="input_slurm_node_count_dynamic_max"></a> [slurm\_node\_count\_dynamic\_max](#input\_slurm\_node\_count\_dynamic\_max) | Maximum number of dynamically allocated nodes allowed in compute partition | `number` | `0` | no |
| <a name="input_slurm_node_count_static"></a> [slurm\_node\_count\_static](#input\_slurm\_node\_count\_static) | Number of statically allocated nodes in compute partition | `number` | `0` | no |
| <a name="input_startup_command"></a> [startup\_command](#input\_startup\_command) | The startup command to be executed when the VM starts up. | `string` | `""` | no |
| <a name="input_zone"></a> [zone](#input\_zone) | The zone to create the GPU cluster. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dashboard_instructions"></a> [dashboard\_instructions](#output\_dashboard\_instructions) | Instructions for accessing the GPU dashboard |
| <a name="output_gke_cluster_connection"></a> [gke\_cluster\_connection](#output\_gke\_cluster\_connection) | The GKE cluster connection Information |
| <a name="output_gke_cluster_name"></a> [gke\_cluster\_name](#output\_gke\_cluster\_name) | The name of the GKE cluster created. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->