# Overview

## Control Plane Options

A3-Mega clusters may be created through either [GKE](https://cloud.google.com/kubernetes-engine) or a [MIG](https://cloud.google.com/compute/docs/instance-groups#managed_instance_groups) via the modules found [here](./terraform/modules/cluster). Due to the recency of A3-Mega's release, features are limited in each control plane, and those limitations are listed below.

| Feature \ Module | `gke` | `mig-cos` |
| --- | --- | --- |
| [VM Image](https://cloud.google.com/compute/docs/images) | [COS-Cloud](https://cloud.google.com/container-optimized-os/docs) | [COS-Cloud](https://cloud.google.com/container-optimized-os/docs) |
| [Compact placement policy](https://cloud.google.com/compute/docs/instances/define-instance-placement) | Yes | Yes |
| [Kubernetes](https://kubernetes.io/) support | Yes | No |

## Quickstart with `gke`

An A3-Mega cluster of eight nodes (two node pools with four nodes each) booting with a COS-Cloud image can be created via GKE by running the following two commands:

```bash
cat >./terraform.tfvars <<EOF
project_id      = "my-project"
region          = "us-central1"
resource_prefix = "my-cluster"
node_pools = [
  {
    zone       = "us-central1-c"
    node_count = 4
  },
  {
    zone       = "us-central1-c"
    node_count = 4
  },
]
EOF

docker run --rm \
  -v "${PWD}:/root/aiinfra/input" \
  -v "${HOME}/.config/gcloud:/root/.config/gcloud" \
  us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest \
  create a3-mega gke


```

A deeper dive into how to use this tool can be found at the [top-level README](../README.md#how-to-provision-a-cluster).

## Quickstart with `mig-cos`

An A3-Mega cluster of eight nodes (two instance groups with four instances each) booting with a COS-Cloud image can be created via a managed instance group by running the following two commands:

```bash
cat >./terraform.tfvars <<EOF
instance_groups = [
  {
    target_size = 4
    zone        = "us-central1-c"
  },
  {
    target_size = 4
    zone        = "us-central1-c"
  },
]
project_id      = "my-project"
region          = "us-central1"
resource_prefix = "my-cluster"
EOF

docker run --rm \
  -v "${PWD}:/root/aiinfra/input" \
  -v "${HOME}/.config/gcloud:/root/.config/gcloud" \
  us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest \
  create a3-mega mig-cos
```

A deeper dive into how to use this tool can be found at the [top-level README](../README.md#how-to-provision-a-cluster).
