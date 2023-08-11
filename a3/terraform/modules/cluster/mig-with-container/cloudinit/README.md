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
| <a name="provider_cloudinit"></a> [cloudinit](#provider\_cloudinit) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [null_resource.validation](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [cloudinit_config.config](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_container"></a> [container](#input\_container) | n/a | <pre>object({<br>    image       = string<br>    cmd         = string<br>    run_at_boot = bool<br>    run_options = object({<br>      custom               = list(string)<br>      enable_cloud_logging = bool<br>      env                  = map(string)<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_custom_gpu_drivers"></a> [custom\_gpu\_drivers](#input\_custom\_gpu\_drivers) | n/a | `bool` | n/a | yes |
| <a name="input_enable_auto_config_apply"></a> [enable\_auto\_config\_apply](#input\_enable\_auto\_config\_apply) | Whenever you update a MIG's instance\_template, Compute Engine automatically applies your updated configuration to new VMs that are added to the group.<br>This flag enables automatic application of an updated configuration to existing VMs.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_group_manager#nested_update_policy), [doc](https://cloud.google.com/compute/docs/instance-groups/rolling-out-updates-to-managed-instance-groups) | `bool` | `true` | no |
| <a name="input_filestores"></a> [filestores](#input\_filestores) | n/a | <pre>list(object({<br>    local_mount  = string<br>    remote_mount = string<br>  }))</pre> | n/a | yes |
| <a name="input_gcsfuses"></a> [gcsfuses](#input\_gcsfuses) | n/a | <pre>list(object({<br>    local_mount  = string<br>    remote_mount = string<br>  }))</pre> | n/a | yes |
| <a name="input_machine_has_gpu"></a> [machine\_has\_gpu](#input\_machine\_has\_gpu) | n/a | `bool` | n/a | yes |
| <a name="input_startup_script"></a> [startup\_script](#input\_startup\_script) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_user-data"></a> [user-data](#output\_user-data) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->