## Overview

This document provides instructions on 
* Building a simple Pingpong PyTorch-based workload on A3 using GPUDirectTCPx
* Running the workload on
    - SLURM
    - GKE


## Pre-Requisites

This guide assumes that you already have created a GKE and SLURM cluster according to this repo with the proper GPU drivers and host images for GPUDirectTCPx.


## Pingpong

### Building the Docker Container

To build the Docker container 

Run the following command

```
sudo docker build . -t "us-central1-docker.pkg.dev/<YOUR PROJECT ID>/<ARTIFACT REGISTRY NAME>/litgpt-full:<ADD TAG HERE>"
```

Upload the Artifact to a Registry 
```
sudo docker push us-central1-docker.pkg.dev/<YOUR PROJECT ID>/<ARTIFACT REGISTRY NAME>/litgpt-full:<ADD TAG HERE>
```

### Running the workload on SLURM

1. Log into the SLURM node

```
PROJECT_ID=<<Project ID>
ZONE=<<Zone>> 
gcloud config set project $PROJECT_ID
gcloud config set compute/zone $ZONE

gcloud compute ssh <<Cluster Node Id >> --zone=$ZONE --project=$PROJECT_ID
```

2. Queue the Workload Job

**Note:** 
* mv `pingpong_container.sh.example` to `pingpong_container.sh.example`
* Update the image information `    us-central1-docker.pkg.dev/<YOUR PROJECT ID>/<ARTIFACT REGISTRY NAME>/litgpt-full:<ADD TAG HERE>`

If these changes are not done and the job will fail.

```
sbatch setup_and_launch_ping_pong_container.sh
```

3. Observe the job 

```
tail -f slurm-<<job_id>>.out
```

### Running the workload on GKE

1. Uninstall any previous Helm 

`helm uninstall <<name>>`

2. Install Helm chart i.e. submit the job

**Note:**
* mv `values.yaml.example` to `values.yaml`
* Populate with the required values.

If these changes are not done and the job will fail.

```
helm install --debug  <<name> -f helm/values.yaml helm/
```
3. Observe the logs 
```kubectl logs --follow <<pod_name>> --all-containers=true```
