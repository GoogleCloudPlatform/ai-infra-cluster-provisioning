# Table of Contents

- [Table of Contents](#table-of-contents)
- [Overview](#overview)
  - [Purpose](#purpose)
  - [Description](#description)
- [Types of clusters](#types-of-clusters)
  - [A3 Clusters](#a3-clusters)
  - [Other Clusters](#other-clusters)
- [Quick Start](#quick-start)
- [How to create a cluster](#how-to-create-a-cluster)
  - [Run the docker image](#run-the-docker-image)
  - [Integrate into an existing terraform project](#integrate-into-an-existing-terraform-project)
  - [Integrate into an existing HPC Toolkit Blueprint](#integrate-into-an-existing-hpc-toolkit-blueprint)
- [Samples for use cases](#samples-for-use-cases)
- [Feature Supports](#feature-supports)

# Overview

## Purpose

The purpose of this tool is to provide a very quick and simple way to provision
a compute cluster on Google Cloud Platform (GCP).

## Description

This repository contains:

- a set of terraform modules that creates GCP resources geared toward running
  AI/ML workloads on [A3 VMs](#a3-clusters).
- an [entrypoint script](./scripts/entrypoint.sh) that will find or create a
  terraform backend in a Google Cloud Storage (GCS) bucket, call the
  appropriate terraform commands using the terraform modules and a user
  provided terraform variables (`tfvars`) file, and upload all logs to the GCS
  backend bucket.
- a [docker image](./Dockerfile) --
  `us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image`
  -- that has all necessary tools installed which calls the entrypoint script
  and creates a cluster for you.

# Types of clusters

## A3 Clusters

An A3 cluster provides the following resources:

- one or many a3-highgpu-8g VM instances (full documentation not available yet,
  description
  [here](https://cloud.google.com/blog/products/compute/introducing-a3-supercomputers-with-nvidia-h100-gpus)).
- five virtual network interface cards (vNIC) -- two H100 GPUs connected to each vNIC.
- [Nvidia GPUDirect](https://developer.nvidia.com/gpudirect).

In the future, any of the [other clusters](#other-clusters) may be an A3 cluster by setting these two variables in the `tfvars` file:

```terraform
machine_type = "a3-highgpu-8g"
network_config = "new_multi_nic"
```

However, due to their recency, A3 clusters are supported by only:

- [`mig-with-container`](./terraform/modules/cluster/mig-with-container): a
  [Managed Instance Group (MIG)](https://cloud.google.com/compute/docs/instance-groups#managed_instance_groups)
  of instances booting with a
  [COS-Cloud image](https://cloud.google.com/container-optimized-os/docs).

## Other Clusters

Clusters of non-A3 machines may be created just as easy as those with A3
machines though it is recommended to use A3 machines in order to acheive
maximum performance. These cluster types are:

- [`gke`](./terraform/modules/cluster/gke):
  [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine)
  cluster of instances booting with a
  [COS-Cloud image](https://cloud.google.com/container-optimized-os/docs).
- [`mig`](./terraform/modules/cluster/mig):
  [Managed Instance Group (MIG)](https://cloud.google.com/compute/docs/instance-groups#managed_instance_groups)
  instances booting with a user-decided
  [VM image](https://cloud.google.com/compute/docs/images)
- [`slurm`](./terraform/modules/cluster/slurm):
  [Slurm](https://slurm.schedmd.com/documentation.html) cluster of instances
  booting with a
  [SchedMD Slurm VM
  image](https://github.com/SchedMD/slurm-gcp/blob/master/docs/images.md#published-image-family).

# Quick Start

Please find the [instructions here](./Quickstart.md) to start GPU cluster creation.

# How to create a cluster

You will need:

- a GCP project with GCE API enabled.
- a GCP account with IAM role
  [`roles/editor`](https://cloud.google.com/iam/docs/understanding-roles#basic).
- [`gcloud` authorization](https://cloud.google.com/sdk/docs/authorizing) --
  you should be able to run `gcloud auth list` and see your account.

There are a few ways to create a cluster:

1. Run the docker image: do this if you don't have any existing infrastructure
  as code.
1. Integrate into an existing terraform project: do this if you already have
  (or plan to have) a terraform project and would like to have the same
  `terraform apply` create this cluster along with all your other
  infrastructure.
1. Integrate into an existing HPC Toolkit Blueprint: do this if you already have
  (or plan to have) an HPC Toolkit Blueprint and would like to have the same
  `ghpc deploy` create this cluster along with all your other infrastructure.

## Run the docker image

For this method, all you need (in addition to the above requirements) is a
`terraform.tfvars` file (user generated or copied from an [example](./samples)) in your
current directory and the ability to run [docker](https://www.docker.com/). In
a terminal, change your current working directory to this one and run the command:

```bash
# create/update the cluster
docker run \
  --rm \
  -v "${HOME}/.config/gcloud:/root/.config/gcloud" \
  -v "${PWD}:/root/aiinfra/input" \
  us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest \
  create mig-with-container

# destroy the cluster
docker run \
  --rm \
  -v "${HOME}/.config/gcloud:/root/.config/gcloud" \
  -v "${PWD}:/root/aiinfra/input" \
  us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest \
  destroy mig-with-container
```

Quick explanation of the `docker run` flags (in same order as above):

- `-v "${HOME}/.config/gcloud:/root/.config/gcloud"` exposes gcloud credentials
  to the container so that it can access your GCP project.
- `-v "${PWD}:/root/aiinfra/input"` exposes the current working directory to
  the container so the tool can read the `terraform.tfvars` file.
- `create/destroy` tells the tool whether it should create or destroy the whole
  cluster.
- `mig-with-container` tells the tool to create a Managed Instance Group and
  start a container at boot. Descriptions of clusters may be found
  [above](#types-of-clusters).

## Integrate into an existing terraform project

For this method, you need to
[install terraform](https://developer.hashicorp.com/terraform/downloads).
Examples of usage as a terraform module can be found in the `main.tf` files in
any of the directories found [here](./samples/a3). Cluster provisioning then
happens the same as any other terraform:

```bash
# assuming the directory containing main.tf is the current working directory

# create/update the cluster
terraform init && terraform validate && terraform apply

# destroy the cluster
terraform init && terraform validate && terraform apply -destroy
```

## Integrate into an existing HPC Toolkit Blueprint

For this method, you need to
[build ghpc](https://github.com/GoogleCloudPlatform/hpc-toolkit#quickstart).
The `a3-mig-with-container` deployment group in the `blueprint.yaml` shows how
to use the `mig-with-container` module in your HPC Toolkit Blueprint. Cluster
provisioning then happens the same as any blueprint:

```bash
# assuming the ghpc binary and blueprint.yaml are both in
# the current working directory

# create/update the cluster
./ghpc create -w ./blueprint.yaml && ./ghpc deploy a3-mig-with-container

# destroy the cluster
./ghpc create -w ./blueprint.yaml && ./ghpc destroy a3-mig-with-container
```

# **Samples for use cases**

| MIG Scenarios | Docker | Terraform | HPC Toolkit |
|---------------|--------|-----------|-------------|
| Simple no GPU | [terraform.tfvars](./samples/mig/simple/terraform.tfvars) | [main.tf](./samples/mig/simple/main.tf) | [blueprint](./samples/mig/simple/simple.yaml) |
| Full featured | [terraform.tfvars](./samples/mig/complex_default_network/terraform.tfvars) | [main.tf](./samples/mig/complex_default_network/main.tf) | [blueprint](./samples/mig/complex_default_network/complex_default_network.yaml) |
| Full featured with new VPC | [terraform.tfvars](./samples/mig/complex_new_network/terraform.tfvars) | [main.tf](./samples/mig/complex_new_network/main.tf) | [blueprint](./samples/mig/complex_new_network/complex_new_network.yaml) |
| Full featured with multi-NIC VPC | [terraform.tfvars](./samples/mig/complex_multi_nic_network/terraform.tfvars) | [main.tf](./samples/mig/complex_multi_nic_network/main.tf) | [blueprint](./samples/mig/complex_multi_nic_network/complex_multi_nic_network.yaml) |
| a3 VM type full featured with multi-NIC VPC | [terraform.tfvars](./samples/mig/a3_multi_nic_network/terraform.tfvars) | [main.tf](./samples/mig/a3_multi_nic_network/main.tf) | [blueprint](./samples/mig/a3_multi_nic_network/a3_multi_nic_network.yaml) |

| MIG-with-Container Scenarios | Docker | Terraform | HPC Toolkit |
|---------------|--------|-----------|-------------|
| Full featured | [terraform.tfvars](./samples/mig-with-container/simple/terraform.tfvars) | [main.tf](./samples/mig-with-container/simple/main.tf) | [blueprint](./samples/mig-with-container/simple/blueprint.yaml) |

| GKE Scenarios | Docker | Terraform | HPC Toolkit |
|---------------|--------|-----------|-------------|
| Simple with no GPU | [terraform.tfvars](./samples/gke/simple/terraform.tfvars) | [main.tf](./samples/gke/simple/main.tf) | [blueprint](./samples/gke/simple/simple.yaml) |
| Full featured with default network | [terraform.tfvars](./samples/gke/complex_gpu_default_network/terraform.tfvars) | [main.tf](./samples/gke/complex_gpu_default_network/main.tf) | [blueprint](./samples/gke/complex_gpu_default_network/complex_gpu_default_network.yaml) |
| Full featured with new network | [terraform.tfvars](./samples/gke/complex_gpu_new_network/terraform.tfvars) | [main.tf](./samples/gke/complex_gpu_new_network/main.tf) | [blueprint](./samples/gke/complex_gpu_new_network/complex_gpu_new_network.yaml) |

| GKE-beta Scenarios | Docker | Terraform | HPC Toolkit |
|--------------------|--------|-----------|-------------|
| Full featured with a3 machines and multi-NIC network | [terraform.tfvars](./samples/gke-beta/a3_multiNIC_network/terraform.tfvars) | Not Supported | Not Supported |

| Slurm Scenarios | Docker | Terraform | HPC Toolkit |
|-----------------|--------|-----------|-------------|
| Simple with no GPU | [terraform.tfvars](./samples/slurm/minimal/terraform.tfvars) | [main.tf](./samples/slurm/minimal/main.tf) | [blueprint](./samples/slurm/minimal/blueprint.yaml) |
| Full featured with multi-NIC network | [terraform.tfvars](./samples/slurm/complex_multi_nic/terraform.tfvars) | [main.tf](./samples/slurm/complex_multi_nic/main.tf) | [blueprint](./samples/slurm/complex_multi_nic/blueprint.yaml) |

# **Feature Supports**

| Features | MIG | MIG-WITH-CONTAINER | GKE | SLURM |
|----------|-----|--------------------|-----|-------|
| RAY Job orchestrator| Supported | Not Supported in COS | Not Supported | Not Supported |
|TCPDirect| Not Supported | Supported | Coming Soon | Not Supported |
|Compact Resource Policy| Supported | Supported | Supported | Supported |
