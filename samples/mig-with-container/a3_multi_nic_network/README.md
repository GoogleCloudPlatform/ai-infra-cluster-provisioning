This provides a sample for creating a complex full featured AI cluster using [Managed Instance
Groups](https://cloud.google.com/compute/docs/instance-groups) and starts a
container on each instance on boot. This cluster uses:
1. Single instance of
   [a3-highgpu-8g](https://cloud.google.com/compute/docs/accelerator-optimized-machines) VM.
1. [nvidia-h100-80gb](https://cloud.google.com/compute/docs/gpus) GPU.
1. [Multi-NIC VPC](https://cloud.google.com/vpc/docs/create-use-multiple-interfaces) in the project.
1. [NFS Filestore mounted in the container](https://cloud.google.com/filestore)
1. GCS Bucket mounted in the container via [GCSFuse](https://cloud.google.com/storage/docs/gcs-fuse).
1. [COS-Cloud machine image](https://cloud.google.com/container-optimized-os/docs).
1. [Deep Learning Container image](https://cloud.google.com/deep-learning-containers).
   to be executed when the VM boots up.

## Usage via Docker Image
Please find detailed set up instruction for docker image
[here](../../../README.md#usage-via-docker-image)

Please copy the [terraform.tfvars](./terraform.tfvars) file to your current working
directory of your local machine. Then follow the below instructions to create the cluster.

```docker
docker pull us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest

docker run \
  -v "${HOME}/.config/gcloud:/root/.config/gcloud" \
  -v "${PWD}:/root/aiinfra/input" \
  --rm us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest \
  create mig-with-container
```

## Usage via Terraform
Please find detailed instructions to set up terraform
[here](../../../README.md#usage-via-terraform)

Please copy the [main.tf](./main.tf) and [terraform.tfvars](./terraform.tfvars) file to your current working
directory of your local machine. Then follow the below instructions to create the cluster
via terraform.

```cmd
terraform init
terraform validate
terraform apply
```
