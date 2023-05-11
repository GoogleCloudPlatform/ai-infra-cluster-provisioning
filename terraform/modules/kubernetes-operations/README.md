
## License

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
Copyright 2023 Google LLC

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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_http"></a> [http](#requirement\_http) | >= 3.3 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.7.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.10 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | n/a |
| <a name="provider_http"></a> [http](#provider\_http) | >= 3.3 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | >= 1.7.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.10 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_service_account_iam_binding.default-workload-identity](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_binding) | resource |
| [kubectl_manifest.nvidia_driver_installer](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_service_account.gke-sa](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [google_client_config.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |
| [google_container_cluster.gke_cluster](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/container_cluster) | data source |
| [http_http.nvidia_driver_installer_manifest](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | An identifier for the resource with format projects/<project\_id>/locations/<region>/clusters/<name>. | `string` | n/a | yes |
| <a name="input_gke_cluster_exists"></a> [gke\_cluster\_exists](#input\_gke\_cluster\_exists) | If set to false then the kubernetes providers will not be configured. | `bool` | `true` | no |
| <a name="input_install_nvidia_driver"></a> [install\_nvidia\_driver](#input\_install\_nvidia\_driver) | If true will create a DaemonSet to install nvidia drivers. | `bool` | `false` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Name of the project to use for instantiating clusters. | `string` | n/a | yes |
| <a name="input_setup_kubernetes_service_account"></a> [setup\_kubernetes\_service\_account](#input\_setup\_kubernetes\_service\_account) | If set, will configure a kubernetes service account and link it to a Google service account.<br><br>Subfields:<br>kubernetes\_service\_account\_name: The Kubernetes Service Account name.<br>kubernetes\_service\_account\_namespace: The Kubernetes Service Account namespace.<br>google\_service\_account\_name: The Google Service Account name. Use empty string for default compute service account. | <pre>object({<br>    kubernetes_service_account_name = string<br>    kubernetes_service_account_namespace = string<br>    google_service_account_name = string<br>  })</pre> | `null` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->