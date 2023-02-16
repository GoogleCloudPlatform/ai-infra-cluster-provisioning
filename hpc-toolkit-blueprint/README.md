## Description

The cluster provisioning tool exposes the functionalities to provisioning a GPU
cluster via Terraform modules. So the GPU cluster provisioning functionalities can 
be directly integrated with HPC toolkit.

This directory provides 

Below is a short introduction to [HPC toolkit](https://cloud.google.com/hpc-toolkit/docs/overview) and the resource materials for it.

## [HPC Toolkit](https://cloud.google.com/hpc-toolkit/docs/overview)

HPC Toolkit is an open-source software offered by Google Cloud which makes it
easy for customers to deploy HPC environments on Google Cloud.

HPC Toolkit allows customers to deploy turnkey HPC environments (compute,
networking, storage, etc.) following Google Cloud best-practices, in a repeatable
manner. The HPC Toolkit is designed to be highly customizable and extensible,
and intends to address the HPC deployment needs of a broad range of customers.

The HPC Toolkit Repo is open-source and available [here](https://github.com/GoogleCloudPlatform/hpc-toolkit)

## Resources

1. [HPC Toolkit Repo](https://github.com/GoogleCloudPlatform/hpc-toolkit)
2. [HPC Toolkit Quickstart](https://github.com/GoogleCloudPlatform/hpc-toolkit#quickstart)
3. [HPC Toolkit dependencies](https://cloud.google.com/hpc-toolkit/docs/setup/install-dependencies)
4. [Installing Terraform](https://developer.hashicorp.com/terraform/downloads)
5. [Installing Packer](https://developer.hashicorp.com/packer/downloads)
6. [Installing Go](https://go.dev/doc/install)
7. [HPC toolkit Troubleshooting](https://github.com/GoogleCloudPlatform/hpc-toolkit#troubleshooting)

## HPC toolkit Blueprints

### [aiinfra-GPU-cluster](../hpc-toolkit-blueprint/aiinfra-gpu-cluster.yaml)