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
| [google-beta_google_compute_instance_template.template](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_compute_instance_template) | resource |
| [google_compute_default_service_account.account](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_default_service_account) | data source |
| [google_compute_image.image](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_disk_size_gb"></a> [disk\_size\_gb](#input\_disk\_size\_gb) | The size of the image in gigabytes for the boot disk of each instance.<br><br>Related docs:<br>- [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#disk_size_gb<br>- [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--boot-disk-size)" | `number` | n/a | yes |
| <a name="input_disk_type"></a> [disk\_type](#input\_disk\_type) | The GCE disk type for the boot disk of each instance.<br><br>Possible values:<br>- `"pd-ssd"`<br>- `"local-ssd"`<br>- `"pd-balanced"`<br>- `"pd-standard"`<br><br>Related docs:<br>- [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#disk_type)<br>- [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--boot-disk-type)" | `string` | n/a | yes |
| <a name="input_guest_accelerator"></a> [guest\_accelerator](#input\_guest\_accelerator) | List of the type and count of accelerator cards attached to each instance.<br>This must be `null` when `machine_type` is of an<br>[accelerator-optimized machine family](https://cloud.google.com/compute/docs/accelerator-optimized-machines)<br>such as A2 or G2.<br><br>Related docs:<br>- [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#guest_accelerator)<br>- [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--accelerator)<br><br>### `guest_accelerator.count`<br><br>The number of the guest accelerator cards exposed to each instance.<br><br>### `guest_accelerator.type`<br><br>The accelerator type resource to expose to each instance.<br><br>Possible values:<br>- `"nvidia-tesla-k80"`<br>- `"nvidia-tesla-p100"`<br>- `"nvidia-tesla-p4"`<br>- `"nvidia-tesla-t4"`<br>- `"nvidia-tesla-v100"`<br><br>Related docs:<br>- [possible values](https://cloud.google.com/compute/docs/gpus#nvidia_gpus_for_compute_workloads) | <pre>object({<br>    count = number<br>    type  = string<br>  })</pre> | n/a | yes |
| <a name="input_machine_image"></a> [machine\_image](#input\_machine\_image) | The image with which this disk will initialize.<br><br>Related docs:<br>- [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#source_image)<br><br>### `machine_image.family`<br><br>The family of images from which the latest non-deprecated image will be selected. Conflicts with `machine_image.name`.<br><br>Related docs:<br>- [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image#name)<br>- [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--image-family)<br><br>### `machine_image.name`<br><br>The name of a specific image. Conflicts with `machin_image.family`.<br><br>Related docs:<br>- [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image#name)<br>- [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--image)<br><br>### `machine_image.project`<br><br>The project\_id to which this image belongs.<br><br>Related docs:<br>- [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image#project)<br>- [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--image-project) | <pre>object({<br>    family  = string<br>    name    = string<br>    project = string<br>  })</pre> | n/a | yes |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | The name of a Google Compute Engine machine type.<br><br>Related docs:<br>- [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#machine_type)<br>- [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--machine-type) | `string` | n/a | yes |
| <a name="input_metadata"></a> [metadata](#input\_metadata) | Metadata key/value pairs to make available from within instances created from<br>this template.<br><br>Related docs:<br>- [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#metadata)<br>- [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--metadata) | `map(string)` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the project in which the resource belongs.<br><br>Related docs:<br>- [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#project) | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | An instance template is a global resource that is not bound to a zone or a<br>region. However, you can still specify some regional resources in an<br>instance template, which restricts the template to the region where that<br>resource resides. For example, a custom subnetwork resource is tied to a<br>specific region.<br><br>Related docs:<br>- [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#region) | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Arbitrary string with which all names of newly created resources will be<br>prefixed. | `string` | n/a | yes |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account) | Service account to attach to the instance.<br><br>Related docs:<br>- [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#service_account)<br><br>### `service_account.email`<br><br>The service account e-mail address. If not given, the default Google<br>Compute Engine service account is used.<br><br>Related docs:<br>- [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#email)<br>- [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--service-account)<br><br>### `service_account.scopes`<br><br>A list of service scopes. Both OAuth2 URLs and gcloud short names are<br>supported. To allow full access to all Cloud APIs, use the<br>`"cloud-platform"` scope. See a complete list of scopes<br>[here](https://cloud.google.com/sdk/gcloud/reference/alpha/compute/instances/set-scopes#--scopes)<br><br>Related docs:<br>- [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#scopes)<br>- [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--scopes) | <pre>object({<br>    email  = string,<br>    scopes = set(string)<br>  })</pre> | n/a | yes |
| <a name="input_startup_script"></a> [startup\_script](#input\_startup\_script) | Script to run at boot on each instance. This is here for convenience and<br>will just be appended to `metadata` under the key `"startup-script"`. | `string` | n/a | yes |
| <a name="input_subnetwork_self_links"></a> [subnetwork\_self\_links](#input\_subnetwork\_self\_links) | Primary subnet self-links for all the VPCs. | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id) | `id` output of the google\_compute\_instance\_template resource created. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->