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

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_resource_policy.placement_policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_resource_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_availability_domain_count"></a> [availability\_domain\_count](#input\_availability\_domain\_count) | The number of availability domains instances will be spread across. If two instances are in different availability domain, they will not be put in the same low latency network<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_resource_policy#availability_domain_count). | `number` | `1` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the project in which the resource belongs.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_resource_policy#project). | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region in which the resource policy(s) has been / will be created.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_resource_policy#region). | `string` | n/a | yes |
| <a name="input_resource_policy_name"></a> [resource\_policy\_name](#input\_resource\_policy\_name) | The name of the resource policy to be created. <br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_resource_policy#name). | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_resource_policy_self_links"></a> [resource\_policy\_self\_links](#output\_resource\_policy\_self\_links) | The self\_links of the resource policy created. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->