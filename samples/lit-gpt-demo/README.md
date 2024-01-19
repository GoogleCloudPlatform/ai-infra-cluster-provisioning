## Overview

This document provides instructions on running a sample PyTorch-based workload on A3 using TCPx, including the limitations with general PyTorch integration.


## Pre-Requisites

This guide assumes that you already have created a GKE cluster according to this repo with the proper GPU drivers and host images for TCPx.


## Limitations


### TCPx Limitations with Pytorch versions

TCPx currently supports a specific NCCL version, which limits the supported versions of Pytorch. The released TCPx binary officially supports NCCL version `2.18.1`, and an unreleased version `2.18.5unpack_memsyncapifix `based on [this commit.](https://github.com/NVIDIA/nccl/commit/321549b7d5e6039a86c0431d0c85e996f9f5fe12) This NCCL version will be installed on the host VM by the nccl-installer daemonset (v3.1.6_2023_10_06). \


To use an official nccl release, we recommend using this base image for your workloads: [nvcr.io/nvidia/pytorch:23.09-py3](nvcr.io/nvidia/pytorch:23.09-py3) .

If you are comfortable with using the unofficial nccl version then you can use another base image, but the pytorch version must still be compatible with 2.18. See the [Nvidia Pytorch support matrix](https://docs.nvidia.com/deeplearning/frameworks/support-matrix/index.html#framework-matrix-2023) for more supported versions.

Some testing has also been done on 2.17.1 (image versions [23.04-py3](http://nvcr.io/nvidia/pytorch:23.04-py3), [23.03-py3](http://nvcr.io/nvidia/pytorch:23.03-py3)) and it is functional, but not considered officially supported.


## LitGPT Sample Workload

If you are building LitGPT from source, we recommend running these commands on a shell with plenty of Memory available (please read our [troubleshooting section](https://docs.google.com/document/d/14x-Lim29ZdcpudJalBn12sQVy9oqutlHr-QOJnvRwxA/edit?resourcekey=0-xfgzT7fofhl9K5qCwSRdLg#heading=h.1zt9nloo6lvr) for more information). If you are consuming the pre-built LitGPT image, then these commands can be run on any shell where you can install docker.


### Environment Setup



1. Make sure you authorize gcloud based on your credentials:
```
gcloud auth login
```
2. Set environment variables for GKE configuration.
```
export CLUSTER_NAME=<name of GKE cluster>
export REGION=<region>
export PROJECT_ID=<project>
```


3. Install `kubectl` and fetch credentials for your GKE cluster.
```
sudo apt-get install kubectl
sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin
gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION --project $PROJECT_ID
```
4. Install Helm.
```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
sudo chmod +x /usr/local/bin/helm
```

### Set up Lit-GPT


### Use Pre-built Docker Image

A pre-built example for quickly running LitGPT is available as a sample workload in the  [ai-infra-cluster-provisioning](https://github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning/tree/develop/sample_workloads/lit-gpt-demo) repo. See [Run LitGPT](#run-lit-gpt) for the next set of instructions.

You can reference the pre-built image at `us-docker.pkg.dev/gce-ai-infra/litgpt-full/litgpt`

Several additional parameters are available in the helm values.yaml file when using the sample workload:


<table>
  <tr>
   <td><strong>Key</strong>
   </td>
   <td><strong>Default Value</strong>
   </td>
   <td><strong>Description</strong>
   </td>
  </tr>
  <tr>
   <td>workload.modelName
   </td>
   <td>Llama-2-70b-hf
   </td>
   <td>LitGPT format of a model to run. Available models <a href="https://github.com/Lightning-AI/lit-gpt/tree/main#-lit-gpt-1">here.</a>
   </td>
  </tr>
  <tr>
   <td>workload.batchSize
   </td>
   <td>6
   </td>
   <td>Training batch size
   </td>
  </tr>
  <tr>
   <td>workload.microBatchSize
   </td>
   <td>6
   </td>
   <td>Training microbatch size
   </td>
  </tr>
</table>



### Build Custom Docker Image

If you would rather modify and set up LitGPT on your own, for example if you want to add custom model configs or additional hyperparameter tuning, follow these steps to build the image from source.


#### Docker Image Setup


##### Setup Artifact Registry

Follow [https://cloud.google.com/artifact-registry/docs/repositories/create-repos](https://cloud.google.com/artifact-registry/docs/repositories/create-repos), make sure to create this for Docker images.

Retrieve the Registry URL by using
```
export REGISTRY_NAME=<repository_name>
export LOCATION=<repository_location>
gcloud artifacts repositories describe $REGISTRY_NAME --location=$LOCATION
```

where `$REGISTRY_NAME` is the repository name that was just created ([https://cloud.google.com/artifact-registry/docs/repositories/create-repos#create-console](https://cloud.google.com/artifact-registry/docs/repositories/create-repos#create-console))

Set` $ARTIFACT_REGISTRY` to the Registry URL returned.
```
export ARTIFACT_REGISTRY=<artifact_registry>
```

**Note:** `ARTIFACT_REGISTRY `is generally in the format of `{LOCATION}-docker.pkg.dev/{PROJECT_ID}/{REGISTRY_NAME}`.


### Setup Docker

We need to install docker since we plan to create our own docker images. Please refer to [https://docs.docker.com/engine/install/](https://docs.docker.com/engine/install/) for a docker installation guide. Once docker is installed, we need to setup docker with gcloud Please run the following (or follow [https://cloud.google.com/artifact-registry/docs/docker/authentication](https://cloud.google.com/artifact-registry/docs/docker/authentication)) \

```
gcloud auth configure-docker
gcloud auth configure-docker $LOCATION-docker.pkg.dev
```


### Setup Docker files and Scripts

Please clone the <code>[ai-infra-cluster-provisioning](https://github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning)</code> repo.

```
git clone https://github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning
```

Once installed, cd into <code>[ai-infra-cluster-provisioning](https://github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning)</code> for the rest of the guide.

Use the following commands to build and push the litgpt image to your artifact repository. If lit-gpt has yet to be cloned, the commands below will install the lit-gpt repository.

**Note: **every time you make a change to lit-gpt you need to re-run this!

```
cd ~/ai-infra-cluster-provisioning/sample_workloads/lit-gpt-demo


sudo -E bash build_and_push_litgpt.sh
```

Once the command is done, a new **image** **tag** will be output in the console. Please keep a record of it, which will be used in the [Helm Config File Setup](#helm-config-file-setup).


### Setting up data

This Lit-GPT training example uses the openwebtext dataset, which can be installed by following [https://github.com/Lightning-AI/lit-gpt/blob/main/tutorials/pretrain_openwebtext.md](https://github.com/Lightning-AI/lit-gpt/blob/main/tutorials/pretrain_openwebtext.md). Please upload these to a Google Cloud Storage (GCS) bucket ([https://cloud.google.com/storage/docs/creating-buckets](https://cloud.google.com/storage/docs/creating-buckets)).

Alternatively, you can find pre-copied versions of this data at:

`gs://litgpt-public-bucket/training-data` (before lit-gpt specific processing) \
`gs://litgpt-public-bucket/openwebtext_dataset` (after lit-gpt specific processing)

**Note:** If you use the `litgpt-public-bucket` to load the dataset then you will not be able to upload your training run data to a GCS bucket. If you want GCS logs for your training run then copy those blobs to a bucket that you have write permissions to.


### Setup for distributed training

In the definition of the `Trainer` object ([https://github.com/Lightning-AI/lit-gpt/blob/main/pretrain/openwebtext_trainer.py#L123-L135](https://github.com/Lightning-AI/lit-gpt/blob/main/pretrain/openwebtext_trainer.py#L123-L135)), we need to add another argument: `num_nodes`. This should match the `nNodes` value in `helm/values.yaml`.

**Note:** Both of the requested code changes above are already present in [https://github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning/blob/develop/sample_workloads/lit-gpt-demo/openwebtext_trainer.py](https://github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning/blob/litgptparams/sample_workloads/lit-gpt-demo/openwebtext_trainer.py)


### Additional Changes to Lit-GPT code


#### Add New Model Configurations

To change the model configuration, please change [https://github.com/Lightning-AI/lit-gpt/blob/main/pretrain/openwebtext_trainer.py#L24](https://github.com/Lightning-AI/lit-gpt/blob/main/pretrain/openwebtext_trainer.py#L24). You can change this model_name to any name in [https://github.com/Lightning-AI/lit-gpt/blob/main/lit_gpt/config.py](https://github.com/Lightning-AI/lit-gpt/blob/main/lit_gpt/config.py). We also recommend adding your own configurations.

For example, try adding: \

```
transformers = [
    dict(name="transformer-100b", block_size=2048, n_layer=55, n_embd=12288, n_head=96, padding_multiple=128),
    dict(name="transformer-175b", block_size=2048, n_layer=96, n_embd=12288, n_head=96, padding_multiple=128),
]
```



#### Hyperparameter changes

Please take a look at [https://github.com/Lightning-AI/lit-gpt/blob/main/pretrain/openwebtext_trainer.py#L24-L46](https://github.com/Lightning-AI/lit-gpt/blob/main/pretrain/openwebtext_trainer.py#L24-L46) 

If you want to customize hyperparameters or parts of the model, please either (1) make the adjustments in the lit-gpt source code or (2) add some flags to adjust in the command line. Look at `litgpt_container_entrypoint.sh` for where exactly the training script is being called.


### Run Lit-GPT

**Note: **If there are any changes to `lit-gpt`, please build and push a newer docker image.


### Helm Config File Setup

Next, create a copy of `helm/values.yaml.example` without the `.example` ending.

```
cp helm/values.yaml.example helm/values.yaml
```

Then, update `helm/values.yaml`. An example configuration would resemble the following:

```
cluster:
  nNodes: 8
  nodePool: np1
network:
  useTcpx: "yes"
  ncclIfnames: 'eth0'
  ncclPlugin: "us-docker.pkg.dev/gce-ai-infra/gpudirect-tcpx/nccl-plugin-gpudirecttcpx-dev:v3.1.6_2023_10_06"
  rxdmContainer: "us-docker.pkg.dev/gce-ai-infra/gpudirect-tcpx/tcpgpudmarxd:v2.0.9"
  disablePmtu: "yes"
workload:
  jobTimestamp: <int: add a timestamp here or unique identifier>
  gcsExperimentBucket: <str: your gcs bucket where experiment logs should go>
  experimentDir: <str: root gcs directory of experiment>
  gcsDataBucket: <str: your gcs bucket where data is located>
  dataDir: <str: location with gcs bucket of where train.bin and val.bin are located>
  image: us-central1-docker.pkg.dev/<YOUR PROJECT ID>/<ARTIFACT REGISTRY NAME>/litgpt-full:<ADD TAG HERE>
  configDirInBucket: null
  batchSize: 6
  microBatchSize: 6
  modelName: Llama-2-70b-hf
```

In the helm config file `values.yaml`, you need to make changes to the following seven flags based on the workload requirements:



* `nodePool`
* `nNodes`
* `jobTimestamp`
* `gcsExperimentBucket`
* `experimentDir`
* `gcsDataBucket`
* `dataDir`
* `image`

`nodePool` refers to the name of the GKE NodePool where the LitGPT job will be run.

`nNodes` refers to the number of GKE GPU nodes in the GKE NodePool (specified by `nodePool`) for running the LitGPT job. Note that the value of `nNodes` cannot exceed the total number of GKE GPU nodes in that NodePool.

`jobTimestamp `needs to be a timestamp or a unique identifier.

`gcsExperimentBucket `refers to a GCS bucket where to store the experimental logs and output.

`experimentDir `refers to a directory in the GCS bucket (specified by `gcsExperimentBucket`) for logging. In the example above,` pir-pythia-6.9b/training_logs/` is a directory already set up for logging in the shared GCS bucket `litgpt-public-bucket`.  \
Alternatively, you can create your own directory (e.g. named `logDir`) under your own GCS bucket (e.g. named `myBucket`). Then the logs will be saved at the target location (e.g. `gs://myBucket`/`logDir`) designated by the parameter `experimentDir`.

`gcsDataBucket `refers to a GCS bucket where your data is stored. In the example above, `litgpt-public-bucket` contains the pre-copied versions of openwebtext dataset. Alternatively, you can use your own GCS bucket (e.g. named `myBucket`).

`dataDir `refers to a directory in the GCS bucket (specified by `gcsDataBucket`) for training data. In the example above, `openwebtext_dataset` is a directory containing the training data in the shared GCS bucket `litgpt-public-bucket`. \
Alternatively, you can create your own directory (e.g. named `dataSourceDir`) under your own GCS bucket (e.g. named `myBucket`). Then the training data will be loaded from the source location (e.g. `gs://myBucket/dataSourceDir/train.bin` and `gs://myBucket/dataSourceDir/val.bin`) designated by the parameter `dataDir`.

`image `refers to the Docker image set up for LitGPT. The value of this flag is in the following format:  `<repository_location>-docker.pkg.dev/<project>/<repository_name>/litgpt-full:<tag>`

**Note:** `<repository_location>`  and` <repository_name>` can be found in section [Setup Artifact Registry](#setup-artifact-registry) above. `&lt;project>` name can be found in the section [Environment Setup](#environment-setup) above. `&lt;tag>` can be found in the section [Setup Docker files and Scripts](#setup-docker-files-and-scripts) above.

Running lit-gpt without the modifications to helm file <code>values.yaml</code> will not work!</strong>

**Note:** before running the command above again, either do `helm uninstall &lt;HELM_EXPERIMENT_NAME>` to fully erase your previous Helm experiment and free the cluster nodes or change the experiment name to a new one so both experiments are kept.

You can check the status of your workload via any of the following:

**Note:** pod0 contains logs that other pods in the same experiment do not contain.


### MFU Calculation

MFU can be calculated by consuming the `metrics.csv` file output by LitGPT. During a training run this file can be found in the litgpt container at `/workspace/out/openwebtext/version_0/metrics.csv` . After training is completed this file will be uploaded as part of the `experimentDir` specified in the helm values.

Step times are presented in the csv as aggregate times in the column `time/train`, so the value used should be 
`time/train[n] - time/train[n-1]`.
 

MFU for this sample workload can be calculated using the formula:

```
mfu = flops_achieved_per_second  /flops_promised_per_second
```
```
flops_achieved_per_second = node_size * number_of_gpus * TFLOPS
```
```
flops achieved in step_time seconds = 
( 6 * batch_size * model_size * context_length ) node_size * number_gpu

flops_achieved_per_second =
(( 6 * batch_size * model_size * context_length ) node_size * number_gpu) / step_time
```
```
mfu =  ( ( 6 * batch_size * model_size * context_length ) node_size * number_gpu ) / ( node_size * number_gpu * TFLOPS * step_time )
``` 

For example, running Llama2-70b on 40 VMs would have you calculate this as:

` ( 6 * (6 * 8 * 40 ) * 4096 * 7e10) / (steptime * 8 * 40 * 1.979e15 / 2 ) = MFU  `



The MFU value is also available in the `metrics.csv` file after 50 iterations at column `throughput/device/mfu`, though we have seen inconsistent numbers reported and recommend calculating it manually.


## Troubleshooting

**Docker build issues**



1. If you run into a “`no` `space` `left` `on` `device`” error message similar to below while building the Docker image (i.e. running the `build_and_push_litgpt.sh` bash script):

```
 => [internal] load build context                                                                                                                   0.3s
 => => transferring context: 3.12MB                                                                                                                 0.3s
------
 > [1/8] FROM nvcr.io/nvidia/pytorch:23.09-py3@sha256:b62b664b830dd9f602e2657f471286a075e463ac75d10ab8e8073596fcb36639:
------
failed to copy: write /usr/local/google/docker/buildkit/content/ingest/035af473dcff6e785cac763b0d0ede8af867a7b1b23cb15b16a319c38410beaf/data: no space left on device
```

Use a machine with more RAM available to successfully build flash-attn. Recommended size is at least 188 GB RAM, but you may be able to install with less.


**Push to Artifact Registry issues**



1. If you run into an unauthorized error as follows:

```
=> ERROR [internal] load metadata for nvcr.io/nvidia/pytorch:23.09-py3 0.1s
------
> [internal] load metadata for nvcr.io/nvidia/pytorch:23.09-py3:
------
failed to solve with frontend dockerfile.v0: failed to solve with frontend gateway.v0: rpc error: code = Unknown desc = failed to fetch anonymous token: unexpected status: 401 Unauthorized
```

Try running the following command to resolve the issue:

```
sudo systemctl restart docker
```

2. If you run into a permission error as follows:

```
denied: Permission "artifactregistry.repositories.uploadArtifacts" denied on resource "projects/<project>/locations/<repository_location>/repositories/<repository_name>" (or it may not exist)
```

Try running the following command to resolve the issue:

```
sudo docker login -u oauth2accesstoken -p "$(gcloud auth print-access-token)" https://$LOCATION-docker.pkg.dev
```

More details can be found [here](https://cloud.google.com/artifact-registry/docs/docker/authentication#token).
