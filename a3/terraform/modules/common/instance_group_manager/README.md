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
| [google-beta_google_compute_instance_group_manager.mig](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_compute_instance_group_manager) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_auto_config_apply"></a> [enable\_auto\_config\_apply](#input\_enable\_auto\_config\_apply) | Whenever you update a MIG's instance\_template, Compute Engine automatically applies your updated configuration to new VMs that are added to the group.<br>This flag enables automatic application of an updated configuration to existing VMs.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_group_manager#nested_update_policy), [doc](https://cloud.google.com/compute/docs/instance-groups/rolling-out-updates-to-managed-instance-groups) | `bool` | `true` | no |
| <a name="input_instance_template_id"></a> [instance\_template\_id](#input\_instance\_template\_id) | The full URL to an instance template from which all new instances of this version will be created.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_instance_group_manager#instance_template). | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the project in which the resource belongs.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#project). | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Arbitrary string with which all names of newly created resources will be prefixed. | `string` | n/a | yes |
| <a name="input_target_size"></a> [target\_size](#input\_target\_size) | The number of running instances for this managed instance group.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_group_manager#target_size), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-groups/managed/create#--size). | `number` | n/a | yes |
| <a name="input_wait_for_instances"></a> [wait\_for\_instances](#input\_wait\_for\_instances) | Whether to wait for all instances to be created/updated before returning. Note that if this is set to true and the operation does not succeed, Terraform will continue trying until it times out.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_instance_group_manager#wait_for_instances). | `bool` | `true` | no |
| <a name="input_zone"></a> [zone](#input\_zone) | The zone that instances in this group should be created in.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_group_manager#zone), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-groups/managed/create#--zone). | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | `id` output of the google\_compute\_instance\_group\_manager resource created. |
| <a name="output_self_link"></a> [self\_link](#output\_self\_link) | `self_link` output of the google\_compute\_instance\_group\_manager resource created |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->