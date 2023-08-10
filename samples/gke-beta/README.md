GKE-beta is experimental. Please use `gke` cluster type to create GKE
clusters. Please refrain from using the `gke-beta` cluster unless it is necessary.

The `gke-beta` cluster type uses gcloud commands to create GKE clusters so many of
the terraform cluster management capabilities are reduced or absent in this option.
This is only an experimental workaround for creation of GKE clusters with A3 machines
with multi-NIC network.

This provides a sample for creating a ML cluster using
[GKE](https://cloud.google.com/kubernetes-engine) with A3 machines and multi-NIC network. This cluster uses:
1. Single GKE cluster with provided
   [version](https://cloud.google.com/kubernetes-engine/versioning#specifying_cluster_version)
   and 1
   [nodepool](https://cloud.google.com/kubernetes-engine/docs/concepts/node-pools)
   with 1 instance of
   [a3-highgpu-8g](https://cloud.google.com/compute/docs/machine-resource) VM.
2. Single GPU of type [nvidia-h100-80g](https://cloud.google.com/compute/docs/gpus).
3. Multi-NIC VPCs in the project.
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
docker run \
  -v "${HOME}/.config/gcloud:/root/.config/gcloud" \
  -v "${PWD}:/root/aiinfra/input" \
  --it us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest \
  create gke-beta
```

## Usage via Terraform
Direct terraform usage is not supported for `gke-beta` clusters.