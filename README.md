# Overview

## Purpose

The purpose of this tool is to provide a very quick and simple way to provision
Google Cloud Platform (GCP) compute clusters of specifically
[accelerator optimized machines](https://cloud.google.com/compute/docs/accelerator-optimized-machines).

## Machine Type Comparison

| Feature \ Machine | A2 | [A3](./a3) |
| --- | --- | --- |
| Nvidia GPU Type | [A100](https://www.nvidia.com/en-us/data-center/a100/) -- 40GB and 80GB | [H100 80GB](https://www.nvidia.com/en-us/data-center/h100/) |
| VM Shapes | [Several](https://cloud.google.com/compute/docs/gpus#a100-gpus) | 8 GPUs |
| GPUDirect-TCPX | Unsupported | Supported |
| Multi-NIC | Unsupported | 5 vNICS -- 1 for CPU and 4 for GPUs (one per pair of GPUs) |

## Repository Content Summary

This repository contains:

- sets of terraform modules that create GCP resources, each tailored toward
  running AI/ML workloads on a specific
  [accelerator optimized machine type](https://cloud.google.com/compute/docs/accelerator-optimized-machines).
- an [entrypoint script](./scripts/entrypoint.sh) that will find or create a
  terraform backend in a Google Cloud Storage (GCS) bucket, call the
  appropriate terraform commands using the terraform modules and a user
  provided terraform variables (`tfvars`) file, and upload all logs to the GCS
  backend bucket.
- a [docker image](./Dockerfile) --
  `us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image`
  -- that has all necessary tools installed which calls the entrypoint script
  and creates a cluster for you.

# How to provision a cluster

## Prerequisites

In order to provision a cluster, the following are required:

- a GCP project with GCE API enabled.
- a GCP account with IAM role
  [`roles/editor`](https://cloud.google.com/iam/docs/understanding-roles#basic).
- [`gcloud` authorization](https://cloud.google.com/sdk/docs/authorizing): explained below.

### Google Cloud Authentication

The command to authorize tools to create resources on your behalf is:

```bash
gcloud auth application-default login
```

The above command is:

- recommended when using the docker image along with exposing your credentials
  to the container with the
  `-v "${HOME}/.config/gcloud:/root/.config/gcloud"`
  flag (explained [below](#run-the-docker-image)). Without this, the tool will
  prompt you on every invocation to authorize itself to create GCP resources
  for you.
- necessary when using this repository in an existing terraform module or
  HPC-Toolkit blueprint.

## Methods

After running through the [prerequisites above](#prerequisites), there are a
few ways to provision a cluster:

1. Run the docker image: do this if you don't have any existing infrastructure
  as code.
1. Integrate into an existing terraform project: do this if you already have
  (or plan to have) a terraform project and would like to have the same
  `terraform apply` create this cluster along with all your other
  infrastructure.
1. Integrate into an existing HPC Toolkit Blueprint: do this if you already have
  (or plan to have) an HPC Toolkit Blueprint and would like to have the same
  `ghpc deploy` create this cluster along with all your other infrastructure.

### Run the docker image

For this method, all you need (in addition to the above requirements) is a
`terraform.tfvars` file (user generated or copied from an example --
[a3-mega](./a3-mega/examples)) in your current directory and the ability to run
[docker](https://www.docker.com/). In a terminal, run:

```bash
# create/update the cluster
docker run \
  --rm \
  -v "${HOME}/.config/gcloud:/root/.config/gcloud" \
  -v "${PWD}:/root/aiinfra/input" \
  us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest \
  create a3-mega mig-cos

# destroy the cluster
docker run \
  --rm \
  -v "${HOME}/.config/gcloud:/root/.config/gcloud" \
  -v "${PWD}:/root/aiinfra/input" \
  us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest \
  destroy a3-mega mig-cos
```

Quick explanation of the `docker run` flags (in same order as above):

- `-v "${HOME}/.config/gcloud:/root/.config/gcloud"` exposes gcloud credentials
  to the container so that it can access your GCP project.
- `-v "${PWD}:/root/aiinfra/input"` exposes the current working directory to
  the container so the tool can read the `terraform.tfvars` file.
- `create/destroy` tells the tool whether it should create or destroy the whole
  cluster.
- `a3-mega` specifies which type of cluster to provision -- this will influence mainly machine type, networking, and startup scripts.
- `mig-cos` tells the tool to create a Managed Instance Group and
  start a container at boot.

### Integrate into an existing terraform project

For this method, you need to
[install terraform](https://developer.hashicorp.com/terraform/downloads).
Examples of usage as a terraform module can be found in the `main.tf` files in
any of the examples -- [a3-mega](./a3-mega/examples). Cluster provisioning then happens
the same as any other terraform:

```bash
# assuming the directory containing main.tf is the current working directory

# create/update the cluster
terraform init && terraform validate && terraform apply -var-file="terraform.tfvars"

# destroy the cluster
terraform init && terraform validate && terraform apply -destroy
```

### Integrate into an existing HPC Toolkit Blueprint

For this method, you need to
[build ghpc](https://github.com/GoogleCloudPlatform/hpc-toolkit#quickstart).
Examples of usage as an HPC Toolkit Blueprint can be found in the
`blueprint.yaml` files in any of the examples -- [a3-mega](./a3-mega/examples). Cluster
provisioning then happens the same as any blueprint:

```bash
# assuming the ghpc binary and blueprint.yaml are both in
# the current working directory

# create/update the cluster
./ghpc create -w ./blueprint.yaml && ./ghpc deploy a3-mega-mig-cos

# destroy the cluster
./ghpc create -w ./blueprint.yaml && ./ghpc destroy a3-mega-mig-cos
```
