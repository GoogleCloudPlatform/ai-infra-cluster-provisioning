## Usage via Docker Image
Please find detailed set up instruction for docker image
[here](../../README.md#usage-via-docker-image)

Please copy the [terraform.tfvars](./terraform.tfvars) file to your local machine at
location `${PWD}/input`. Then follow the below instructions to create the cluster.

```docker
docker pull us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest

docker run \
  -v "${HOME}/.config/gcloud:/root/.config/gcloud" \
  -v "${PWD}/input:/root/aiinfra/input" \
  --rm us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest \
  create mig 
```

## Usage via Terraform
Please find detailed instructions to set up terraform
[here](../../README.md#usage-via-terraform)

Please copy the [main.tf](./main.tf) and [terraform.tfvars](./terraform.tfvars) to your local machine at
location `${PWD}/terraform`. Then follow the below instructions to create the cluster
via terraform.

```cmd
cd ${PWD}/input
terraform init
terraform validate
terraform apply
```