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

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [cloudinit_config.config](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |
| [cloudinit_config.config-gpu](https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_container"></a> [container](#input\_container) | n/a | <pre>object({<br>    image   = string<br>    cmd     = string<br>    env     = map(string)<br>    options = list(string)<br>  })</pre> | n/a | yes |
| <a name="input_enable_cloud_logging"></a> [enable\_cloud\_logging](#input\_enable\_cloud\_logging) | n/a | `bool` | `true` | no |
| <a name="input_filestores"></a> [filestores](#input\_filestores) | n/a | <pre>list(object({<br>    local_mount  = string<br>    remote_mount = string<br>  }))</pre> | n/a | yes |
| <a name="input_gcsfuses"></a> [gcsfuses](#input\_gcsfuses) | n/a | <pre>list(object({<br>    local_mount  = string<br>    remote_mount = string<br>  }))</pre> | n/a | yes |
| <a name="input_machine_has_gpu"></a> [machine\_has\_gpu](#input\_machine\_has\_gpu) | n/a | `bool` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_user-data"></a> [user-data](#output\_user-data) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->