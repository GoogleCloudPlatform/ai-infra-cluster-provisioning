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
| <a name="provider_google-beta"></a> [google-beta](#provider\_google-beta) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google-beta_google_compute_resource_policy.new_placement_policy](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_compute_resource_policy) | resource |
| [google-beta_google_compute_resource_policy.existing_placement_policy](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/data-sources/google_compute_resource_policy) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_existing_resource_policy_name"></a> [existing\_resource\_policy\_name](#input\_existing\_resource\_policy\_name) | The name of the existing resource policy. <br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_resource_policy#name). | `string` | `null` | no |
| <a name="input_new_resource_policy_name"></a> [new\_resource\_policy\_name](#input\_new\_resource\_policy\_name) | The name of the new resource policy to be created. <br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_resource_policy#name). | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the project in which the resource belongs.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_resource_policy#project). | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region in which the resource policy(s) has been / will be created.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_resource_policy#region). | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_resource_name"></a> [resource\_name](#output\_resource\_name) | The self\_link of the resource policy created. |
| <a name="output_resource_self_link"></a> [resource\_self\_link](#output\_resource\_self\_link) | The self\_link of the resource policy created. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->