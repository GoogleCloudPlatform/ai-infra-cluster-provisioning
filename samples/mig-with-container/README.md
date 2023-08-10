# The cluster

This configuration creates a cluster of eight
[`a3-highgpu-8g`](https://cloud.google.com/blog/products/compute/introducing-a3-supercomputers-with-nvidia-h100-gpus)
VM instances. Each instance has:
- eight [NVidia H100 GPUs](https://www.nvidia.com/en-us/data-center/h100/),
- five [NICs](https://cloud.google.com/vpc/docs/multiple-interfaces-concepts)
  (one VPC for the host network and four dedicated to the GPUs),
- a [COS-Cloud](https://cloud.google.com/container-optimized-os/docs) machine
  image,
- TCPX, Nvidia GPU drivers, and NCCL plugin installed

# The tfvars file

The `terraform.tfvars` file is what configures the cluster. Detailed
descriptions of each variable can be found in
[this `README`](../../../terraform/modules/cluster/mig-with-container/README.md).
All optional variables may be omitted to use their default values.

Required variables:
- `project_id`
- `resource_prefix`
- `target_size`
- `zone`

# How to create this cluster

Refer to [this section](../../../README.md#how-to-provision-a-cluster).
