
## License

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
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
| [kubectl_manifest.installer_daemonsets](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_service_account.ksa](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [google_client_config.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |
| [google_container_cluster.gke_cluster](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/container_cluster) | data source |
| [http_http.installer_daemonsets](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | An identifier for the resource with format projects/<project\_id>/locations/<region>/clusters/<name>. | `string` | n/a | yes |
| <a name="input_daemonsets"></a> [daemonsets](#input\_daemonsets) | Daemonsets to install with kubectl apply -f <daemonset> | `map(string)` | n/a | yes |
| <a name="input_enable"></a> [enable](#input\_enable) | This module cannot have for\_each, count, or depends\_on attributes because<br>it contains provider blocks. Conditionally enable this moduel by setting<br>this variable. | `bool` | n/a | yes |
| <a name="input_gcp_sa"></a> [gcp\_sa](#input\_gcp\_sa) | Google Cloud Platform service account email to which the<br>Kubernetes Service Account (KSA) will be bound. | `string` | n/a | yes |
| <a name="input_ksa"></a> [ksa](#input\_ksa) | The configuration for setting up Kubernetes Service Account (KSA) after GKE<br>cluster is created.<br><br>- `name`: The KSA name to be used for Pods<br>- `namespace`: The KSA namespace to be used for Pods<br><br>Related Docs: [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity) | <pre>object({<br>    name      = string<br>    namespace = string<br>  })</pre> | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Name of the project to use for instantiating clusters. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->