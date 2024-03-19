# The cluster

This configuration creates two Managed Instance Groups of four
[`a3-megagpu-8g`](https://cloud.google.com/blog/products/compute/introducing-a3-supercomputers-with-nvidia-h100-gpus)
VM instances each (eight instances in total). Each instance has:
- eight [NVidia H100 GPUs](https://www.nvidia.com/en-us/data-center/h100/),
- nine [NICs](https://cloud.google.com/vpc/docs/multiple-interfaces-concepts)
  (one VPC for the host network and eight dedicated to the GPUs),
- a [COS-Cloud](https://cloud.google.com/container-optimized-os/docs) machine
  image,
- TCPX, Nvidia GPU drivers, and NCCL plugin installed

# The tfvars file

The `terraform.tfvars` file is what configures the cluster. Detailed
descriptions of each variable can be found in
[this `README`](../../terraform/modules/cluster/mig-cos/README.md).
All optional variables may be omitted to use their default values.

Required variables:
- `instance_groups`
- `project_id`
- `region`
- `resource_prefix`

# How to create this cluster

Refer to [this section](../../../README.md#how-to-provision-a-cluster).

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_a3-mega-mig-cos"></a> [a3-mig-cos](#module\_a3-mega-mig-cos) | github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning//a3-mega/terraform/modules/cluster/mig-cos | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_instance_groups"></a> [instance\_groups](#input\_instance\_groups) | n/a | `any` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | n/a | `any` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | n/a | `any` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | n/a | `any` | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
