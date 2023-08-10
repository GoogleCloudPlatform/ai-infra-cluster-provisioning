# Overview

## Purpose

The purpose of this tool is to provide a very quick and simple way to provision
a Google Cloud Platform (GCP) A3 compute cluster.

## What is an A3 cluster?

An A3 cluster provides the following resources:

- one or many `a3-highgpu-8g` VM instances (documentation not available yet,
  description
  [here](https://cloud.google.com/blog/products/compute/introducing-a3-supercomputers-with-nvidia-h100-gpus))
- five virtual network interface cards (vNIC) -- two Nvidia H100 GPUs connected to each vNIC
- TCPX (documentation not available yet)

## Control plane options

A3 clusters may be created through either [GKE](https://cloud.google.com/kubernetes-engine) or a [MIG](https://cloud.google.com/compute/docs/instance-groups#managed_instance_groups) via the modules found [here](./terraform/modules/cluster). Due to the recency of A3's release, features are limited in each control plane, and those limitations are listed below.

| Feature \ Module | `gke` | `mig-with-container` |
| --- | --- | --- |
| [VM Image](https://cloud.google.com/compute/docs/images) | [COS-Cloud](https://cloud.google.com/container-optimized-os/docs) | [COS-Cloud](https://cloud.google.com/container-optimized-os/docs) |
| TCPX | Yes | Yes |
| [Kubernetes](https://kubernetes.io/) support | Yes | No |

## Quickstart with `gke`

An A3 cluster of eight nodes (two node pools with four nodes per node pool) booting with a COS-Cloud image can be created via GKE by running the following two commands:

```bash
cat >./terraform.tfvars <<EOF
project_id = "my-project"
resource_prefix = "my-cluster"
region = "us-central1"

node_pools = [
  {
    zone                     = "us-central1-c"
    node_count               = 4
    machine_type             = "a3-highgpu-8g"
    enable_compact_placement = true
  },
  {
    zone                     = "us-central1-c"
    node_count               = 4
    machine_type             = "a3-highgpu-8g"
    enable_compact_placement = true
  },
]
EOF

docker run --rm -v "${PWD}:/root/aiinfra/input" \
  us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest \
  create gke
```

A deeper dive into how to use this tool can be found [below](#how-to-provision-a-cluster).

## Quickstart with `mig-with-container`

An A3 cluster of eight nodes booting with a COS-Cloud image can be created via a managed instance group by running the following two commands:

```bash
cat >./terraform.tfvars <<EOF
project_id = "my-project"
resource_prefix = "my-cluster"
target_size = 8
zone = "us-central1-c"
EOF

docker run --rm -v "${PWD}:/root/aiinfra/input" \
  us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest \
  create mig-with-container
```

A deeper dive into how to use this tool can be found [below](#how-to-provision-a-cluster).

## Repository content summary

This repository contains:

- a set of terraform modules that creates GCP resources geared toward running
  AI/ML workloads on [A3 VMs](#what-is-an-a3-cluster).
- an [entrypoint script](./scripts/entrypoint.sh) that will find or create a
  terraform backend in a Google Cloud Storage (GCS) bucket, call the
  appropriate terraform commands using the terraform modules and a user
  provided terraform variables (`tfvars`) file, and upload all logs to the GCS
  backend bucket.
- a [docker image](./Dockerfile) --
  `us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image`
  -- that has all necessary tools installed which calls the entrypoint script
  and creates a cluster for you.

# Prerequisites

In order to provision a cluster, the following are required:

- a GCP project with GCE API enabled.
- a GCP account with IAM role
  [`roles/editor`](https://cloud.google.com/iam/docs/understanding-roles#basic).
- [`gcloud` authorization](https://cloud.google.com/sdk/docs/authorizing): explained below.

## Google Cloud Authentication

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

# How to provision a cluster

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
  start a container at boot.

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
