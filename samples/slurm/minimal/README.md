The slurm cluster created with this `terraform.tfvars` file has:
- a single partition named `compute` consisting of two nodes in the `us-central1-a` zone, each with:
  - a disk of size 128GB and type `pd-standard`
  - machine type of `a2-highgpu-2g`
  - boot image of project `schedmd-slurm-public` and family `schedmd-v5-slurm-22-05-8-ubuntu-2004-lts`
- a controller node in the `us-central1-a` zone with:
  - a disk of size 50GB and type `pd-ssd`
  - machine type of `c2-standard-4`
  - boot image of project `schedmd-slurm-public` and family `schedmd-v5-slurm-22-05-8-ubuntu-2004-lts`
- a login node in the `us-central1-a` zone with:
  - a disk of size 50GB and type `pd-standard`
  - machine type of `n2-standard-2`
  - boot image of project `schedmd-slurm-public` and family `schedmd-v5-slurm-22-05-8-ubuntu-2004-lts`
- one new VPC with which all the above nodes are connected

## Usage via Docker Image

Detailed docker instructions can be found
[here](../../../README.md#usage-via-docker-image).

Copy the [terraform.tfvars](./terraform.tfvars) file to your current
working directory on your local machine and run:

```bash
docker pull us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest

docker run -it --rm \
  -v "${HOME}/.config/gcloud:/root/.config/gcloud" \
  -v "${PWD}:/root/aiinfra/input" \
  us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest \
  create slurm
```

## Usage via Terraform

Detailed terraform instructions can be found
[here](../../../README.md#usage-via-terraform).

Copy the [main.tf](./main.tf) and [terraform.tfvars](./terraform.tfvars) file
to your current working directory on your local machine and run:
```bash
terraform init
terraform validate
terraform apply
```

## Usage via HPC Toolkit Blueprint

Copy the [blueprint.yaml](./blueprint.yaml) file into your
[hpc-toolkit](https://github.com/GoogleCloudPlatform/hpc-toolkit) directory and
run:
```bash
./ghpc create ./blueprint.yaml
./ghpc deploy slurm-cluster
```
