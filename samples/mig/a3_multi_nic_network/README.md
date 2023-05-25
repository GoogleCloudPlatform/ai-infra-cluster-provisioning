This provides a sample for creating a complex full featured AI cluster using [Managed Instance
Groups](https://cloud.google.com/compute/docs/instance-groups). This cluster uses:
1. Single instance of
   [a3-highgpu-8g](https://cloud.google.com/compute/docs/accelerator-optimized-machines) VM.
1. [nvidia-h100-80gb](https://cloud.google.com/compute/docs/gpus) GPU.
1. [Multi-NIC VPC](https://cloud.google.com/vpc/docs/create-use-multiple-interfaces) in the project.
1. [NFS Filestore](https://cloud.google.com/filestore)
1. GCS Bucket mounted in the VM via [GCSFuse](https://cloud.google.com/storage/docs/gcs-fuse).
1. [Deep Learning VM (DLVM) images](https://cloud.google.com/deep-learning-vm/docs/images).
1. [Ray](https://docs.ray.io/en/master/ray-overview/index.html) orchestrator.
1. [Startup script](https://cloud.google.com/compute/docs/instances/startup-scripts)
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
  create mig 
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
