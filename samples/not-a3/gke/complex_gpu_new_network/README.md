This provides a sample for creating a complex full featured AI cluster using [GKE](https://cloud.google.com/kubernetes-engine). This cluster uses:
1. Single GKE cluster with provided
   [version](https://cloud.google.com/kubernetes-engine/versioning#specifying_cluster_version)
   and 1
   [nodepool](https://cloud.google.com/kubernetes-engine/docs/concepts/node-pools)
   with 1 instance of
   [a2-highgpu-1g](https://cloud.google.com/compute/docs/machine-resource) VM.
2. Single GPU of type [nvidia-tesla-a100](https://cloud.google.com/compute/docs/gpus).
3. New single [VPC](https://cloud.google.com/vpc/docs/vpc).
4. [COS-Containerd image](https://cloud.google.com/kubernetes-engine/docs/concepts/using-containerd).
5. Nvidia GPU driver installed using [daemonset](https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/nvidia-driver-installer/cos/daemonset-preloaded-latest.yaml).
6. [Kubernetes Service
   Account](https://cloud.google.com/kubernetes-engine/docs/how-to/kubernetes-service-accounts)
   setup in the GKE cluster.

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
