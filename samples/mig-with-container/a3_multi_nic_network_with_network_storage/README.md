# Description

## The cluster

This configuration creates a cluster of four
[a3-highgpu-8g](https://cloud.google.com/blog/products/compute/introducing-a3-supercomputers-with-nvidia-h100-gpus)
VM instances. Each instance has:
- eight [NVidia H100 GPUs](https://www.nvidia.com/en-us/data-center/h100/),
- five [NICs](https://cloud.google.com/vpc/docs/multiple-interfaces-concepts)
  (one VPC for the host network and four dedicated to the GPUs),
- a [COS-Cloud](https://cloud.google.com/container-optimized-os/docs) machine
  image,
- a custom container started at boot (recommended:
  [Deep Learning Container](https://cloud.google.com/deep-learning-containers)
  image),
- a newly created [Filestore](https://cloud.google.com/filestore) mounted in
  the container via NFS,
- a pre-existing [GCS bucket](https://cloud.google.com/storage) mounted in the
  container via [GCSFuse](https://cloud.google.com/storage/docs/gcs-fuse),
- a startup script to run on each boot which installs TCPDirect

## The tfvars file

The `terraform.tfvars` file is what configures the cluster. Detailed descriptions of each variable can be found in [this README](../../../terraform/modules/cluster/mig-with-container/README.md). All optional variables may be omitted to use their default values.

Required variables:
- `project_id`
- `resource_prefix`
- `target_size`
- `zone`

Optional variables:
- `container`
- `cos_extensions_flags`
- `disk_size_gb`
- `disk_type`
- `filestore_new`
- `gcsfuse_existing`
- `guest_accelerator`
- `labels`
- `machine_image`
- `machine_type`
- `metadata`
- `network_config`
- `service_account`
- `startup_script`
- `wait_for_instances`

# How to create this cluster

You will need:
- a GCP project with GCE API enabled
- a GCP account with IAM roles:
  - [`roles/compute.admin`](https://cloud.google.com/iam/docs/understanding-roles#compute-engine-roles)
  - [`roles/iam.serviceAccountUser`](https://cloud.google.com/iam/docs/understanding-roles#iam.serviceAccountUser)
- [`gcloud` authorization](https://cloud.google.com/sdk/docs/authorizing) --
  you should be able to run `gcloud auth list` and see your account.

There are three ways to create this cluster:
1. run the docker image: do this if you don't have any existing infrastructure
  as code.
1. integrate into an existing terraform project: do this if you already have
  (or plan to have) a terraform project and would like to have the same
  `terraform apply` create this cluster along with all your other
  infrastructure.
1. integrate into an existing HPC Toolkit Blueprint: do this if you already have
  (or plan to have) an HPC Toolkit Blueprint and would like to have the same
  `ghpc deploy` create this cluster along with all your other infrastructure.

## Run the docker image

For this method, all you need (in addition to the above requirements) is the
`terraform.tfvars` file found in this directory and the ability to run
[docker](https://www.docker.com/). In a terminal, change your current working
directory to this one and run the command:
```bash
docker run \
  --rm \
  -v "${HOME}/.config/gcloud:/root/.config/gcloud" \
  -v "${PWD}:/root/aiinfra/input" \
  us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest \
  create mig-with-container
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
The module `a3-mig` in the `main.tf` shows how to use the `mig-with-container`
module in your terraform project. Cluster provisioning then happens the same as
any other terraform:
```bash
# assuming this directory is the current working directory
terraform init \
&& terraform validate \
&& terraform apply
```

## Integrate into an existing HPC Toolkit Blueprint

For this method, you need to
[build ghpc](https://github.com/GoogleCloudPlatform/hpc-toolkit#quickstart).
The `a3-mig-with-container` deployment group in the `blueprint.yaml` shows how
to use the `mig-with-container` module in your HPC Toolkit Blueprint. Cluster
provisioning then happens the same as any blueprint:
```bash
# assuming the ghpc binary and the blueprint.yaml are both in your current
# working directory
./ghpc create ./blueprint.yaml \
&& ./ghpc deploy a3-mig-with-container
```
