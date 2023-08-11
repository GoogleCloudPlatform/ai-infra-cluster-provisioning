This provides a sample for creating a complex full featured AI cluster using [Managed Instance
Groups](https://cloud.google.com/compute/docs/instance-groups) via Terraform using
GCS bucket as a backend. With GCs as backend for terraform, the terraform states are
stored in the GCS bucket so the cluster can be managed via multiple users from
multiple machines as long as they have read and write access to the backed GCS bucket.

This cluster uses:
1. Single instance of
   [a2-highgpu-1g](https://cloud.google.com/compute/docs/accelerator-optimized-machines) VM.
1. [Nvidia A100](https://cloud.google.com/compute/docs/gpus) GPU.
1. Default VPC in the project.
1. [NFS Filestore](https://cloud.google.com/filestore)
1. GCS Bucket mounted in the VM via [GCSFuse](https://cloud.google.com/storage/docs/gcs-fuse).
1. [Deep Learning VM (DLVM) images](https://cloud.google.com/deep-learning-vm/docs/images).
1. [Ray](https://docs.ray.io/en/master/ray-overview/index.html) orchestrator.
1. [Startup script](https://cloud.google.com/compute/docs/instances/startup-scripts)
   to be executed when the VM boots up.

## Usage via Terraform
Please find detailed instructions to set up terraform
[here](../../../README.md#usage-via-terraform)

Please copy the [main.tf](./main.tf) and [terraform.tfvars](./terraform.tfvars) file to your current working
directory of your local machine. Then follow the below instructions to create the cluster
via terraform.

```bash
terraform init
terraform validate
terraform apply
```
