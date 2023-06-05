This provides a sample for creating a simple AI cluster using [GKE](https://cloud.google.com/kubernetes-engine). This cluster uses:
1. Single GKE cluster with 1 [node
   pool](https://cloud.google.com/kubernetes-engine/docs/concepts/node-pools)
  with 1 instance of
   [n1-standard-1](https://cloud.google.com/compute/docs/machine-resource) VM.
2. Default VPC in the project.
3. [COS-Containerd image](https://cloud.google.com/kubernetes-engine/docs/concepts/using-containerd).

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
  create gke 
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
