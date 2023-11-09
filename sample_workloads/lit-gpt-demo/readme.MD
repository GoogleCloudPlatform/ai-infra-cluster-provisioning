## Overview 

This document provides instructions on running a sample PyTorch-based workload on A3 using TCPx, including the limitations with general PyTorch integration.


## Pre-Requisites 

This guide assumes that you already have created a GKE cluster with an A3 nodepool.


## Running sample Torch workflow 


#### TCPx Limitations with Pytorch versions 

TCPx currently supports a specific NCCL version, which limits the supported versions of Pytorch. The released TCPx binary officially supports NCCL version `2.18.1`, and an unreleased version `2.18.5unpack_memsyncapifix `based on [this commit.](https://github.com/NVIDIA/nccl/commit/321549b7d5e6039a86c0431d0c85e996f9f5fe12) This NCCL version will be installed on the host VM by the nccl-installer daemonset (v3.1.6). \


To use an official nccl release, we recommend using this base image for your workloads: [nvcr.io/nvidia/pytorch:23.05-py3](nvcr.io/nvidia/pytorch:23.05-py3) .

If you are comfortable with using the unofficial nccl version then you can use another base image, but the pytorch version must still be compatible with 2.18. See the [Nvidia Pytorch support matrix](https://docs.nvidia.com/deeplearning/frameworks/support-matrix/index.html#framework-matrix-2023) for more supported versions.

Some testing has also been done on 2.17.1 (image versions [23.04-py3](http://nvcr.io/nvidia/pytorch:23.04-py3), [23.03-py3](http://nvcr.io/nvidia/pytorch:23.03-py3)) and it is functional, but not considered officially supported.


#### Integrating TCPx Into Pytorch 

At runtime additional commands must be run within the training container to overwrite the nccl binary used by pytorch. The TCPx binary hooks into the nccl library present on the Host VM. Pytorch also ships with a nccl binary that is used by default. Without running the following script, pytorch will use its default nccl binary without the LD_LIBRARY_PATH reference to tcpx. 

```
sudo mkdir /usr/local/tcpx_exec &
sudo mount --bind /usr/local/tcpx_exec /usr/local/tcpx_exec &
sudo mount -o remount,exec /usr/local/tcpx_exec &
sudo cp -r /usr/local/tcpx/lib64 /usr/local/tcpx_exec &
sudo rm /lib/x86_64-linux-gnu/libnccl.so.2.18.1 sudo rm /opt/hpcx/nccl_rdma_sharp_plugin/lib/libnccl-net.so.0.0.0 &
sudo rm /opt/hpcx/nccl_rdma_sharp_plugin/lib/libnccl-net.so.0 &
sudo chmod go+w /etc/ld.so.conf.d/nvidia.conf &
sudo echo /usr/local/tcpx_exec/lib64 >> /etc/ld.so.conf.d/nvidia.conf &
export NCCL_NET=GPUDirectTCPX_v7 &
export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/usr/local/tcpx_exec/lib64 &
<YOUR_ENTRYPOINT>
```


## LitGPT Sample Workload 


#### Environment Setup 



1. Set environment variables for configuration

```
export CLUSTER_NAME=<cluster>
export REGION=<region>
export PROJECT_ID=<project>
export ARTIFACT_REGISTRY=<artifact_registry>
```

2. Install kubectl
```
sudo apt-get install kubectl
sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin
gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION --project $PROJECT_ID
```
3. Install helm:
```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 
chmod 700 get_helm.sh 
./get_helm.sh
sudo chmod +x /usr/local/bin/helm
```


### Consume From Sample Workloads 

A pre-built example for quickly running LitGPT is available as a sample workload in this repo. See [Run LitGPT](#run-lit-gpt) for the next set of instructions.

Several additional parameters are available in the helm chart template by using the sample workload:


<table>
  <tr>
   <td>Key
   </td>
   <td>Sample Value
   </td>
   <td>Description
   </td>
  </tr>
  <tr>
   <td>BATCH_SIZE
   </td>
   <td>5
   </td>
   <td>Training batch size
   </td>
  </tr>
  <tr>
   <td>MICRO_BATCH_SIZE
   </td>
   <td>125
   </td>
   <td>Training microbatch size
   </td>
  </tr>
</table>



### Consume from Source 

If you would rather modify and set up LitGPT on your own, for example if you want to add custom model configs or additional hyperparameter tuning, follow these steps to build the image from source.


#### Docker Image Setup 

Setup Artifact Registry

Follow [https://cloud.google.com/artifact-registry/docs/repositories/create-repos](https://cloud.google.com/artifact-registry/docs/repositories/create-repos), make sure to create this for Docker images.

Retrieve the Registry URL by using

```
gcloud artifacts repositories describe $REGISTRY_NAME --location=$REGION
```

Set` $ARTIFACT_REGISTRY` to the Registry URL returned.

Install `lit-gpt` locally at hash `6178c7cc58ba82e5cce138e7a3159c384e2d3b0f`. Newer versions of `lit-gpt` as of 10/26/2023 do not include flash attention 2. If you are using the scripts in `lit-gpt-demo` then clone the repository directly into the `lit-gpt-demo` directory.

Use the following commands to build and push the litgpt image to your artifact repository.

```
export BASE_IMAGE="$ARTIFACT_REGISTRY/litgpt-base"
export FULL_IMAGE="$ARTIFACT_REGISTRY/litgpt-full"
export LITGPT_PATH="lit-gpt"
cd ai-infra-cluster-provisioning/sample_workloads/lit-gpt-demo
git clone https://github.com/Lightning-AI/lit-gpt.git
cd lit-gpt
git checkout 6178c7cc58ba82e5cce138e7a3159c384e2d3b0f
cd ..
mv Dockerfile lit-gpt
bash build_and_push_litgpt.sh
```

**NOTE**: every time you make a change to lit-gpt you need to re-run this!


##### Setting up data 

This Lit-GPT training example uses the openwebtext dataset, which can be installed by following [https://github.com/Lightning-AI/lit-gpt/blob/main/tutorials/pretrain_openwebtext.md](https://github.com/Lightning-AI/lit-gpt/blob/main/tutorials/pretrain_openwebtext.md). Please upload these to a GCP bucket.

Alternatively, you can find pre-copied versions of this data at:

`gs://litgpt-public-bucket/training-data` (before lit-gpt specific processing) \
`gs://litgpt-public-bucket/openwebtext_dataset` (after lit-gpt specific processing)

Once you have openwebtext dataset in a gcs bucket, you will also need to update [https://github.com/Lightning-AI/lit-gpt/blob/main/pretrain/openwebtext_trainer.py#L27](https://github.com/Lightning-AI/lit-gpt/blob/main/pretrain/openwebtext_trainer.py#L27).

Please change `data_dir = Path("data") / name` to `data_dir = Path("/data")`


##### Setup for distributed training 

In the definition of the `Trainer` object ([https://github.com/Lightning-AI/lit-gpt/blob/main/pretrain/openwebtext_trainer.py#L123-L135](https://github.com/Lightning-AI/lit-gpt/blob/main/pretrain/openwebtext_trainer.py#L123-L135)), we need to add another argument: `num_nodes`. This should match the `nNodes` value in `helm/values.yaml`.

**Note: **Both of the requested code changes above are already present in [https://github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning/blob/develop/sample_workloads/lit-gpt-demo/openwebtext_trainer.py](https://github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning/blob/litgptparams/sample_workloads/lit-gpt-demo/openwebtext_trainer.py)


#### Additional Changes to Lit-GPT code 


#### Add New Model Configurations 

To change the model configuration, please change [https://github.com/Lightning-AI/lit-gpt/blob/main/pretrain/openwebtext_trainer.py#L24](https://github.com/Lightning-AI/lit-gpt/blob/main/pretrain/openwebtext_trainer.py#L24). You can change this model_name to any name in [https://github.com/Lightning-AI/lit-gpt/blob/main/lit_gpt/config.py](https://github.com/Lightning-AI/lit-gpt/blob/main/lit_gpt/config.py). We also recommend adding your own configurations.

For example, try adding:

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

**NOTE**: If there are any changes to `lit-gpt`, please build and push a newer docker image.


#### Helm Config File Setup 

Next, update `helm/values.yaml.example`. An example configuration would resemble the following:

```
cluster:
  nNodes: 8
  nodePool: np1
network:
  useTcpx: "yes"
  ncclIfnames: 'eth0'
  ncclPlugin: "us-docker.pkg.dev/gce-ai-infra/gpudirect-tcpx/nccl-plugin-gpudirecttcpx-dev:v3.1.6_2023_10_06"
  rxdmContainer: "us-docker.pkg.dev/gce-ai-infra/gpudirect-tcpx/tcpgpudmarxd:v2.0.7"
  disablePmtu: "yes"
workload:
  gcsBucket: litgpt-public-bucket
  jobTimestamp: 1
  experimentDir: pythia-6.9b/
  dataDir: openwebtext_dataset
  image: us-docker.pkg.dev/gce-ai-infra/litgpt-full/litgpt
  configDirInBucket: null
```

For example, you have a gcs bucket  `myBucket`. You have data (`train.bin` and `val.bin`) that is located in `dataDir`. The gsutil URI would then be `gs://myBucket/dataDir/train.bin` and `gs://myBucket/dataDir/val.bin`. Additionally, you want to save logs in `logDir` (also in `myBucket`)

In the helm config file `values.yaml`, we would make the following changes

```
workload:
  gcsBucket: myBucket
  jobTimestamp: <int: add a timestamp here or unique identifier>
  experimentDir: logDir
  dataDir: dataDir
```

Running lit-gpt without the modifications to helm file <code>values.yaml</code> WILL NOT WORK!</strong>

```
helm install --debug litgpt-test -f helm/values.yaml helm/
```

**Note**: before running the command above again, either do `helm uninstall litgpt-test` or change the experiment name (`litgpt-test` is the experiment name).

You can check the status of your workload via any of the following:

```
kubectl get pods | grep litgpt
kubectl logs <ENTER POD NAME> -c litgpt
kubectl get pod <ENTER POD NAME> --output=yaml
```