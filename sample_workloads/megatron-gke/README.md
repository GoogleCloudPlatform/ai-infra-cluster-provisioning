# Running Megatron-LM/llama2 on A3 Mega

## Overview

This document provides instructions for running a container-based PyTorch
workload (Megatron-LM) on A3 Mega.


## Prerequisites

Before proceeding, set up a Google Kubernetes Engine (GKE) clusters.

For more information about creating a GKE cluster, see
https://cloud.google.com/kubernetes-engine/docs/how-to/gpu-bandwidth-gpudirect-tcpx

### Setup your environment

Set up environment variables for some common parameters:

```
export CLUSTER_NAME=<CLUSTER_NAME>
export REGION=<REGION>
export ZONE=<ZONE>
export PROJECT_ID=<PROJECT_ID>
```

### Setup gcloud

Configure gcloud to use your GPC credentials for authentication:

```
gcloud auth login
```

For more information, see
[Authenticate for using the gcloud CLI](https://cloud.google.com/docs/authentication/gcloud).

Install `kubectl` and the GKE gcloud plugin:

```
sudo apt-get install kubectl
sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin
```

Fetch credentials for your GKE cluster:

```
gcloud container clusters get-credentials $CLUSTER_NAME \
  --zone $ZONE \
  --project $PROJECT_ID
```

### Install Helm

Install [Helm](https://helm.sh/) (if not already installed):

```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh && rm get_helm.sh
sudo chmod +x /usr/local/bin/helm
```


### Topology-Aware Scheduler

You can use the topology-aware scheduler to deploy your GKE Pods to nodes that
have a specified GPU topology.

In the following `kubectl` commands, we will use the files directly from a
repository. Alternatively, the
[repo](https://github.com/GoogleCloudPlatform/container-engine-accelerators/tree/master/gpudirect-tcpxo/topology-scheduler)
can be cloned locally and the `kubectl` commands can reference the local files
instead.

For more information, see:
https://github.com/GoogleCloudPlatform/container-engine-accelerators/tree/master/gpudirect-tcpxo/topology-scheduler

Setup the service account:

```
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/gpudirect-tcpxo/topology-scheduler/service-account.yaml
```

Install the topology scheduler scripts in a configmap:

```
# Download the files to use
curl -OL  https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/gpudirect-tcpxo/topology-scheduler/schedule-daemon.py
curl -OL  https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/gpudirect-tcpxo/topology-scheduler/label-nodes-daemon.py

kubectl -n kube-system create configmap topology-scheduler-scripts \
  --from-file=schedule-daemon.py=schedule-daemon.py \
  --from-file=label-nodes-daemon.py=label-nodes-daemon.py

```

Install the topology label daemonset and topology scheduler Pod:

```
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/gpudirect-tcpxo/topology-scheduler/label-nodes-daemon.yaml
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/gpudirect-tcpxo/topology-scheduler/schedule-daemon.yaml
```

You can observe the actions of the topology scheduler using:

```
kubectl -n kube-system logs topology-scheduler-pod
```

## Running the workload

### Build the Dockerfile and push to the GCP Artifact Registry

Create a [GCS bucket](https://cloud.google.com/storage/docs/creating-buckets)
and a [Docker repository](https://cloud.google.com/artifact-registry/docs/docker/store-docker-container-images).
In the `scripts/setup-and-configure-resources.sh` script, replace the bucket
and repository names with the ones you created, and then run the script:

```
bash scripts/setup-and-configure-resources.sh
```

Build and push the image `pytorch-megatron:23.11-py3`. You should ensure the
artifact repository name in the `scripts/build-and-push-docker-image.sh` file
matches what you used in the `scripts/setup-and-configure-resources.sh` script.
You can also edit the Docker image tag name before pushing.

```
bash scripts/build-and-push-docker-image.sh
```

> Note: This image is based off of `nvcr.io/nvidia/pytorch:23.11-py3` with
> minimal change.


### Launch Megatron-LM Llama2 Benchmark

> Note: Edit `selected-configuration.sh` to specify your configuration. For some
> example configurations, see [`sample-configurations`](sample-configurations/).
> Also edit `helm/values.yaml` to specify your defined GCS bucket and Docker
> image (defined in the previous [step](#build-the-dockerfile-and-push-to-the-gcp-artifact-registry)).

```
helm install <HELM-EXPERIMENT-NAME> helm/ --values helm/values.yaml
```

> Note: If you want to run the Helm experiment multiple times, you can either
erase the existing experiment using the `helm uninstall` command or you can
create a new experiment with a different name.

The experiment writes metrics from Nsight profiling to the GCS bucket specified
in the `megatron-experiments`.