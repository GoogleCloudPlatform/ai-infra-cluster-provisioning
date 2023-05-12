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

| Name | Version |
|------|---------|
| <a name="provider_google-beta"></a> [google-beta](#provider\_google-beta) | >= 4.12 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_compute_instance_template"></a> [compute\_instance\_template](#module\_compute\_instance\_template) | ../../common/instance_template | n/a |
| <a name="module_dashboard"></a> [dashboard](#module\_dashboard) | ../../common/dashboard | n/a |
| <a name="module_filestore"></a> [filestore](#module\_filestore) | github.com/GoogleCloudPlatform/hpc-toolkit//modules/file-system/filestore// | v1.17.0 |
| <a name="module_gcsfuse"></a> [gcsfuse](#module\_gcsfuse) | github.com/GoogleCloudPlatform/hpc-toolkit//modules/file-system/pre-existing-network-storage// | v1.17.0 |
| <a name="module_network"></a> [network](#module\_network) | ../../common/network | n/a |
| <a name="module_startup"></a> [startup](#module\_startup) | github.com/GoogleCloudPlatform/hpc-toolkit//modules/scripts/startup-script/ | v1.17.0 |

## Resources

| Name | Type |
|------|------|
| [google-beta_google_compute_instance_group_manager.mig](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_compute_instance_group_manager) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_disk_size_gb"></a> [disk\_size\_gb](#input\_disk\_size\_gb) | The size of the image in gigabytes for the boot disk of each instance.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#disk_size_gb), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--boot-disk-size). | `number` | `128` | no |
| <a name="input_disk_type"></a> [disk\_type](#input\_disk\_type) | The GCE disk type for the boot disk of each instance.<br><br>Possible values: `["pd-ssd", "local-ssd", "pd-balanced", "pd-standard"]`<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#disk_type), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--boot-disk-type). | `string` | `"pd-standard"` | no |
| <a name="input_enable_ops_agent"></a> [enable\_ops\_agent](#input\_enable\_ops\_agent) | Install [Google Cloud Ops Agent](https://cloud.google.com/stackdriver/docs/solutions/agents/ops-agent). | `bool` | `true` | no |
| <a name="input_enable_ray"></a> [enable\_ray](#input\_enable\_ray) | Install [Ray](https://docs.ray.io/en/latest/cluster/getting-started.html). | `bool` | `false` | no |
| <a name="input_filestore_new"></a> [filestore\_new](#input\_filestore\_new) | Configurations to mount newly created network storage. Each object describes NFS file-servers to be hosted in Filestore.<br><br>Related docs: [hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit/tree/main/modules/file-system/filestore#inputs).<br><br>------------<br>`filestore_new.filestore_tier`<br><br>The service tier of the instance.<br><br>Possible values: `["BASIC_HDD", "BASIC_SSD", "HIGH_SCALE_SSD", "ENTERPRISE"]`.<br><br>Related docs: [hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit/tree/main/modules/file-system/filestore#input_filestore_tier), [gcloud](https://cloud.google.com/sdk/gcloud/reference/filestore/instances/create#--tier).<br><br>------------<br>`filestore_new.local_mount`<br><br>Mountpoint for this filestore instance.<br><br>Related docs: [hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit/tree/main/modules/file-system/filestore#input_local_mount).<br><br>------------<br>`filestore_new.size_gb`<br><br>Storage size of the filestore instance in GB.<br><br>Related docs: [hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit/tree/main/modules/file-system/filestore#input_local_mount), [gcloud](https://cloud.google.com/sdk/gcloud/reference/filestore/instances/create#--file-share). | <pre>list(object({<br>    filestore_tier = string<br>    local_mount    = string<br>    size_gb        = number<br>  }))</pre> | `[]` | no |
| <a name="input_gcsfuse_existing"></a> [gcsfuse\_existing](#input\_gcsfuse\_existing) | Configurations to mount existing network storage. Each object describes Cloud Storage Buckets to be mounted with Cloud Storage FUSE.<br><br>Related docs: [hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit/tree/main/modules/file-system/pre-existing-network-storage#inputs).<br><br>------------<br>`gcsfuse_existing.local_mount`<br><br>The mount point where the contents of the device may be accessed after mounting.<br><br>Related docs: [hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit/tree/main/modules/file-system/pre-existing-network-storage#input_local_mount).<br><br>------------<br>`gcsfuse_existing.remote_mount`<br><br>Bucket name without “gs://”.<br><br>Related docs: [hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit/tree/main/modules/file-system/pre-existing-network-storage#input_remote_mount). | <pre>list(object({<br>    local_mount  = string<br>    remote_mount = string<br>  }))</pre> | `[]` | no |
| <a name="input_guest_accelerator"></a> [guest\_accelerator](#input\_guest\_accelerator) | List of the type and count of accelerator cards attached to each instance. This must be `null` when `machine_type` is of an [accelerator-optimized machine family](https://cloud.google.com/compute/docs/accelerator-optimized-machines) such as A2 or G2.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#guest_accelerator), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--accelerator).<br><br>------------<br>`guest_accelerator.count`<br><br>The number of the guest accelerator cards exposed to each instance.<br><br>------------<br>`guest_accelerator.type`<br><br>The accelerator type resource to expose to each instance.<br><br>[Possible values](https://cloud.google.com/compute/docs/gpus#nvidia_gpus_for_compute_workloads): `["nvidia-tesla-k80", "nvidia-tesla-p100", "nvidia-tesla-p4", "nvidia-tesla-t4", "nvidia-tesla-v100"]`. | <pre>object({<br>    count = number<br>    type  = string<br>  })</pre> | `null` | no |
| <a name="input_machine_image"></a> [machine\_image](#input\_machine\_image) | The image with which this disk will initialize.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#source_image).<br><br>------------<br>`machine_image.family`<br><br>The family of images from which the latest non-deprecated image will be selected. Conflicts with `machine_image.name`.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image#name), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--image-family).<br><br>------------<br>`machine_image.name`<br><br>The name of a specific image. Conflicts with `machine_image.family`.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image#name), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--image).<br><br>------------<br>`machine_image.project`<br><br>The project\_id to which this image belongs.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_image#project), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--image-project). | <pre>object({<br>    family  = string<br>    name    = string<br>    project = string<br>  })</pre> | <pre>{<br>  "family": "pytorch-latest-gpu-debian-11-py310",<br>  "name": null,<br>  "project": "deeplearning-platform-release"<br>}</pre> | no |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | The name of a Google Compute Engine machine type.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#machine_type), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--machine-type). | `string` | `"a2-highgpu-2g"` | no |
| <a name="input_network_config"></a> [network\_config](#input\_network\_config) | The network configuration to specify the type of VPC to be used.<br><br>Possible values: `["default", "new_multi_nic", "new_single_nic"]` | `string` | `"default"` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP Project ID to which the cluster will be deployed. | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Arbitrary string with which all names of newly created resources will be prefixed. | `string` | n/a | yes |
| <a name="input_service_account"></a> [service\_account](#input\_service\_account) | Service account to attach to the instance.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#service_account).<br><br>------------<br>`service_account.email`<br><br>The service account e-mail address. If not given, the default Google Compute Engine service account is used.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#email), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--service-account).<br><br>------------<br>`service_account.scopes`<br><br>A list of service scopes. Both OAuth2 URLs and gcloud short names are supported. To allow full access to all Cloud APIs, use the `"cloud-platform"` scope. See a complete list of scopes [here](https://cloud.google.com/sdk/gcloud/reference/alpha/compute/instances/set-scopes#--scopes).<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#scopes), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-templates/create#--scopes). | <pre>object({<br>    email  = string,<br>    scopes = set(string)<br>  })</pre> | `null` | no |
| <a name="input_startup_script"></a> [startup\_script](#input\_startup\_script) | Shell script -- the actual script (not the filename). | `string` | `null` | no |
| <a name="input_startup_script_file"></a> [startup\_script\_file](#input\_startup\_script\_file) | Shell script filename. | `string` | `null` | no |
| <a name="input_target_size"></a> [target\_size](#input\_target\_size) | The number of running instances for this managed instance group.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_group_manager#target_size), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-groups/managed/create#--size). | `number` | n/a | yes |
| <a name="input_zone"></a> [zone](#input\_zone) | The zone that instances in this group should be created in.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_group_manager#zone), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/instance-groups/managed/create#--zone). | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_instructions"></a> [instructions](#output\_instructions) | Instructions for accessing the dashboard |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->