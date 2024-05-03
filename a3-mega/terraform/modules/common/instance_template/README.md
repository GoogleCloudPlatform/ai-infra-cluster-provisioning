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
| <a name="module_resource_policy"></a> [resource\_policy](#module\_resource\_policy) | ../resource_policy | n/a |

## Resources

| Name | Type |
|------|------|
| [google-beta_google_compute_instance_template.template](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_compute_instance_template) | resource |
| [google_compute_default_service_account.account](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_default_service_account) | data source |
| [google_compute_image.image](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_disk_size_gb"></a> [disk\_size\_gb](#input\_disk\_size\_gb) | The size of the image in gigabytes for the boot disk of each instance.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#disk_size_gb), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--boot-disk-size). | `number` | n/a | yes |
| <a name="input_disk_type"></a> [disk\_type](#input\_disk\_type) | The GCE disk type for the boot disk of each instance.<br><br>Possible values: `["pd-ssd", "local-ssd", "pd-balanced", "pd-standard"]`<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#disk_type), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--boot-disk-type). | `string` | n/a | yes |
| <a name="input_existing_resource_policy_name"></a> [existing\_resource\_policy\_name](#input\_existing\_resource\_policy\_name) | The name of the existing resource policy. <br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_resource_policy#name). | `string` | `null` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | A set of key/value label pairs to assign to instances created from this template.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#labels), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--labels). | `map(string)` | n/a | yes |
| <a name="input_machine_image"></a> [machine\_image](#input\_machine\_image) | The image with which this disk will initialize.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#source_image).<br><br>------------<br>`machine_image.family`<br><br>The family of images from which the latest non-deprecated image will be selected. Conflicts with `machine_image.name`.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image#name), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--image-family).<br><br>------------<br>`machine_image.name`<br><br>The name of a specific image. Conflicts with `machine_image.family`.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image#name), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--image).<br><br>------------<br>`machine_image.project`<br><br>The project\_id to which this image belongs.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image#project), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--image-project). | <pre>object({<br>    family  = string<br>    name    = string<br>    project = string<br>  })</pre> | n/a | yes |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | The name of a Google Compute Engine machine type. There are [many possible values](https://cloud.google.com/compute/docs/machine-resource).<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#machine_type), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--machine-type). | `string` | n/a | yes |
| <a name="input_maintenance_interval"></a> [maintenance\_interval](#input\_maintenance\_interval) | Specifies the frequency of planned maintenance events. 'PERIODIC' is th only supported value for maintenance\_interval.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#maintenance_interval). | `string` | n/a | yes |
| <a name="input_metadata"></a> [metadata](#input\_metadata) | Metadata key/value pairs to make available from within instances created from this template.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#metadata), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--metadata). | `map(string)` | n/a | yes |
| <a name="input_network_self_links"></a> [network\_self\_links](#input\_network\_self\_links) | The network self-links for all the VPCs. | `list(string)` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the project in which the resource belongs.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#project). | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | An instance template is a global resource that is not bound to a zone or a region. However, you can still specify some regional resources in an instance template, which restricts the template to the region where that resource resides. For example, a custom subnetwork resource is tied to a specific region.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#region). | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Arbitrary string with which all names of newly created resources will be prefixed. | `string` | n/a | yes |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account) | Service account to attach to the instance.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#service_account).<br><br>------------<br>`service_account.email`<br><br>The service account e-mail address. If not given, the default Google Compute Engine service account is used.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#email), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--service-account).<br><br>------------<br>`service_account.scopes`<br><br>A list of service scopes. Both OAuth2 URLs and gcloud short names are supported. To allow full access to all Cloud APIs, use the `"cloud-platform"` scope. See a complete list of scopes [here](https://cloud.google.com/sdk/gcloud/reference/alpha/compute/instances/set-scopes#--scopes).<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#scopes), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--scopes). | <pre>object({<br>    email  = string,<br>    scopes = set(string)<br>  })</pre> | n/a | yes |
| <a name="input_startup_script"></a> [startup\_script](#input\_startup\_script) | Script to run at boot on each instance. This is here for convenience and will just be appended to `metadata` under the key `"startup-script"`. | `string` | n/a | yes |
| <a name="input_subnetwork_self_links"></a> [subnetwork\_self\_links](#input\_subnetwork\_self\_links) | The subnet self-links for all the VPCs. | `list(string)` | n/a | yes |
| <a name="input_use_compact_placement_policy"></a> [use\_compact\_placement\_policy](#input\_use\_compact\_placement\_policy) | The flag to create and use a superblock level compact placement policy for the instances. Currently GCE supports using only 1 placement policy.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#resource_policies). | `bool` | `false` | no |
| <a name="input_use_static_naming"></a> [use\_static\_naming](#input\_use\_static\_naming) | Flag to determine whether to use static naming for instance\_template name. If used static naming, then instance\_template cannot be updated. it needs to be destroyed and then recreated.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#name_prefix). | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | `id` output of the google\_compute\_instance\_template resource created. |
| <a name="output_name"></a> [name](#output\_name) | `name` output of the google\_compute\_instance\_template resource created. |
| <a name="output_self_link"></a> [self\_link](#output\_self\_link) | `self_link` output of the google\_compute\_instance\_template resource created |
| <a name="output_service_account"></a> [service\_account](#output\_service\_account) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->