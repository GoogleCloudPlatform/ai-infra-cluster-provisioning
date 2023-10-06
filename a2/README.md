# Overview

## Control Plane Options

A2 clusters are created through a [MIG](https://cloud.google.com/compute/docs/instance-groups#managed_instance_groups) via the modules found [here](./terraform/modules/cluster).

## Quickstart with `mig`

An A2 cluster of 4 `a2-highgpu-1g` nodes (2 instance groups with 2 instances each) booting with a DLVM image can be created via a managed instance group by running the following two commands:

```bash
cat >./terraform.tfvars <<EOF
instance_groups = [
  {
    target_size = 2
    zone        = "us-central1-c"
  },
  {
    target_size = 2
    zone        = "us-central1-c"
  },
]
project_id      = "my-project"
region          = "us-central1"
resource_prefix = "my-cluster"
EOF

docker run --rm -v "${HOME}/.config/gcloud:/root/.config/gcloud" \
  -v "${PWD}:/root/aiinfra/input" \
  us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest \
  create a2 mig
```

A deeper dive into how to use this tool can be found at the [top-level README](../README.md#how-to-provision-a-cluster).
