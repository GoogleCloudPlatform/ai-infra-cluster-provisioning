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
| <a name="provider_google"></a> [google](#provider\_google) | >= 3.83 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_firewall.external-ingress](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.iap-ssh](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.internal-ingress](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.internal-ingress-gpus](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_network.gpus](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_network.nic0](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_subnetwork.gpus](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_compute_subnetwork.nic0](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_compute_network.nic0](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_network) | data source |
| [google_compute_subnetwork.nic0](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_subnetwork) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_nic0_existing"></a> [nic0\_existing](#input\_nic0\_existing) | Existing network to attach to nic0. Setting to null will create a new network for it. | <pre>object({<br>    network_name    = string<br>    subnetwork_name = string<br>  })</pre> | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the project in which the resource belongs.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_subnetwork#project). | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region in which the subnetwork(s) has been / will be created.<br><br>Related docs: [terraform](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_subnetwork#region), [gcloud](https://cloud.google.com/sdk/gcloud/reference/compute/networks/subnets/create#--region). | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Arbitrary string with which all names of newly created resources will be prefixed. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_network_ids"></a> [network\_ids](#output\_network\_ids) | Network ids of all the VPCs |
| <a name="output_network_names"></a> [network\_names](#output\_network\_names) | Network names of all the VPCs |
| <a name="output_network_self_links"></a> [network\_self\_links](#output\_network\_self\_links) | Network self-links of all the VPCs |
| <a name="output_subnetwork_names"></a> [subnetwork\_names](#output\_subnetwork\_names) | Subnet names of all the VPCs |
| <a name="output_subnetwork_self_links"></a> [subnetwork\_self\_links](#output\_subnetwork\_self\_links) | Subnet self-links of all the VPCs |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->