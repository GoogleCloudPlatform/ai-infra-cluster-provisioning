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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 3.83 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | >= 4.12 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_default_vpc"></a> [default\_vpc](#module\_default\_vpc) | github.com/GoogleCloudPlatform/hpc-toolkit//modules/network/pre-existing-vpc// | v1.17.0 |
| <a name="module_multiple_new_vpcs"></a> [multiple\_new\_vpcs](#module\_multiple\_new\_vpcs) | github.com/GoogleCloudPlatform/hpc-toolkit//modules/network/vpc// | v1.17.0 |
| <a name="module_single_new_vpc"></a> [single\_new\_vpc](#module\_single\_new\_vpc) | github.com/GoogleCloudPlatform/hpc-toolkit//modules/network/vpc// | v1.17.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_network_config"></a> [network\_config](#input\_network\_config) | The network configuration to specify the type of VPC to be used.<br><br>Possible values: `["default", "new_multi_nic", "new_single_nic"]` | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the project in which the resource belongs.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_subnetwork#project). | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region in which the subnetwork(s) has been / will be created.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_subnetwork#region), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/networks/subnets/create#--region). | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Arbitrary string with which all names of newly created resources will be prefixed. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_network_id"></a> [network\_id](#output\_network\_id) | ID of the network |
| <a name="output_subnetwork_self_links"></a> [subnetwork\_self\_links](#output\_subnetwork\_self\_links) | Primary subnet self-links of all the VPCs |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->