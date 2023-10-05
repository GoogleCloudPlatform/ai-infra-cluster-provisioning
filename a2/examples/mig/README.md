# The cluster

This configuration creates two Managed Instance Groups of four
[`a2-highgpu-1g`](https://cloud.google.com/compute/docs/gpus#a100-40gb)
VM instances each (eight instances in total). Each instance has:
- eight [NVidia A100 GPUs](https://www.nvidia.com/en-us/data-center/a100/),
- one [NIC]
- a [DLVM](https://cloud.google.com/deep-learning-vm) machine
  image,
- Nvidia GPU drivers

# The tfvars file

The `terraform.tfvars` file is what configures the cluster. Detailed
descriptions of each variable can be found in
[this `README`](../../terraform/modules/cluster/mig/README.md).
All optional variables may be omitted to use their default values.

Required variables:
- `instance_groups`
- `project_id`
- `region`
- `resource_prefix`

# How to create this cluster

Refer to [this section](../../../a2/README.md#quickstart-with-mig).

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_a2-mig"></a> [a2-mig](#module\_a2-mig) | github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning//a2/terraform/modules/cluster/mig | n/a |

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
