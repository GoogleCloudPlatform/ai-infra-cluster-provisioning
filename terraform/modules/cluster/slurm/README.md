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

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_compute_node_group"></a> [compute\_node\_group](#module\_compute\_node\_group) | github.com/GoogleCloudPlatform/hpc-toolkit//community/modules/compute/schedmd-slurm-gcp-v5-node-group// | v1.16.0 |
| <a name="module_compute_partition"></a> [compute\_partition](#module\_compute\_partition) | github.com/GoogleCloudPlatform/hpc-toolkit//community/modules/compute/schedmd-slurm-gcp-v5-partition// | v1.16.0 |
| <a name="module_slurm_controller"></a> [slurm\_controller](#module\_slurm\_controller) | github.com/GoogleCloudPlatform/hpc-toolkit//community/modules/scheduler/schedmd-slurm-gcp-v5-controller// | v1.16.0 |
| <a name="module_slurm_login"></a> [slurm\_login](#module\_slurm\_login) | github.com/GoogleCloudPlatform/hpc-toolkit//community/modules/scheduler/schedmd-slurm-gcp-v5-login// | v1.16.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_deployment_name"></a> [deployment\_name](#input\_deployment\_name) | The deployment name. Default value is name\_prefix-depl. | `string` | `null` | no |
| <a name="input_instance_template_compute"></a> [instance\_template\_compute](#input\_instance\_template\_compute) | Self link to the instance template to be used for creating compute nodes. | `string` | n/a | yes |
| <a name="input_instance_template_controller"></a> [instance\_template\_controller](#input\_instance\_template\_controller) | Self link to the instance template to be used for creating controller node. | `string` | n/a | yes |
| <a name="input_instance_template_login"></a> [instance\_template\_login](#input\_instance\_template\_login) | Self link to the instance template to be used for creating login node. | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels to add to the instances. List key, value pairs. | `map(any)` | `{}` | no |
| <a name="input_network_self_link"></a> [network\_self\_link](#input\_network\_self\_link) | Self link of network to which the cluster will be attached | `string` | n/a | yes |
| <a name="input_network_storage"></a> [network\_storage](#input\_network\_storage) | Storage to mount on all instances | <pre>list(object({<br>    server_ip             = string,<br>    remote_mount          = string,<br>    local_mount           = string,<br>    fs_type               = string,<br>    mount_options         = string,<br>    client_install_runner = map(string)<br>    mount_runner          = map(string)<br>  }))</pre> | `[]` | no |
| <a name="input_node_count_dynamic_max"></a> [node\_count\_dynamic\_max](#input\_node\_count\_dynamic\_max) | Maximum number of dynamically allocated nodes allowed in compute partition | `number` | n/a | yes |
| <a name="input_node_count_static"></a> [node\_count\_static](#input\_node\_count\_static) | Number of statically allocated nodes in compute partition | `number` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Name of the project to use for instantiating clusters. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | GCP region where to create resources. | `string` | n/a | yes |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account) | Service account to attach to the instance. See https://www.terraform.io/docs/providers/google/r/compute_instance_template.html#service_account. | <pre>object({<br>    email  = string,<br>    scopes = set(string)<br>  })</pre> | n/a | yes |
| <a name="input_subnetwork_self_link"></a> [subnetwork\_self\_link](#input\_subnetwork\_self\_link) | Self link of subnetwork to which the cluster will be attached | `string` | n/a | yes |
| <a name="input_zone"></a> [zone](#input\_zone) | GCP zone where to create resources. Only use if multi\_zonal is false. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->