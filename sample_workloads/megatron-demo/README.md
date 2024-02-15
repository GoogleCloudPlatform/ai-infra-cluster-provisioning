# NeMo Megatron on GKE

This document demonstrates running [NeMo Megatron](https://github.com/NVIDIA/NeMo) on A3 VMs in a GKE environment usng TCPx technology. The A3 VMs have 8x NVIDIA H100 GPUs and 4x 200 Gbps NICs and leverage TCPx for direct GPU to NIC transfers.

### Prerequisites

- [Gcloud Cli](https://cloud.google.com/sdk/docs/install)
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/install-cli)
- [Helm](https://helm.sh/docs/intro/install/)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- [Envsubst](https://manpages.ubuntu.com/manpages/trusty/man1/envsubst.1.html)

In addition to the above tools, you will need: 
- Quota for NVIDIA H100 GPUs
- Quota for FileStore
- Access to [NVIDIA NGC Big NLP Training](https://registry.ngc.nvidia.com/orgs/ea-bignlp/containers/bignlp-training) Docker images

## Infrastructure Setup

### Select project, zone, and resource prefix
Adjust the values in `set-enviroment.sh` to suit your case.
```
export PROJECT=supercomputer-testing

# GKE cluster name, location, and scale
export PREFIX=sufkha-nemo-demo-test
export REGION=us-central1
export ZONE=us-central1-c
export E2_NODE_COUNT=4
export A3_NODE_COUNT=4

# GKE cluster shared Filestore (i.e. NFS)
# Tier is one of {basic, standard, premium, zonal, or enterprise} 
export NFS_SIZE="1Ti"
export NFS_TIER="enterprise" 
```
The E2 nodes are used for system services (e.g. DNS pods, custom controllers). Some of these variables are exposed to Terraform by defining additional environment variables using the `TF_VAR_` prefix. 

Enable this environment in your shell by running:
```
source set-environment.sh
```
*This environment should be present in your shell in subsequent steps.*

### Create a GCS bucket that will retain the Terraform state
Create a GCS bucket that will retain Terraform state.
```
bash scripts/create-terraform-gcs-backend-bucket.sh
```
*Note: Most bash scripts in this example are one-line gcloud commands wrapped for convenience.*

Then initialize the Terraform state using this GCS bucket.
```
terraform init \
  -backend-config="bucket=$PREFIX" \
  -backend-config="prefix=$PREFIX"
```

### Create a GKE cluster with A3 VMs
Create a GKE cluster with the desired count of A3 VMs.
```
terraform apply
```
This step may take 15 or more minutes. You can check the progress of the cluster provisioning by visiting [Cloud Console](https://console.cloud.google.com/kubernetes/list/overview).

### Augment your cluster with a pool of E2 VMs

Add a node pool with the desired count of E2 VMs in your GKE cluster in order to host system services (e.g. DNS pods, custom controllers). *The Terraform module will integate this in the future.*
```
bash scripts/create-e2-node-pool.sh 
```
### Fetch the credentials from your cluster to direct `kubectl` commands

Fetch the credentials from your GKE cluster.
```
bash scripts/fetch-gke-credentials-for-kubectl.sh
```
Now any `kubectl` commands will be applied against your GKE cluster.

### Install the GPU drivers

Trigger installation of the GPU drivers.
```
bash scripts/install-gpu-drivers.sh
```

Check the GPU devices are exposed.
```
kubectl get pods -n kube-system | grep nvidia
```

You should see all pods to be listed in `Running` state.

### Adjust GKE networking such that the VPCs are in device mode

Adjust GKE networking to place the VPCs in device mode.
```
cat manifests/enable-network-pass-through.yaml | envsubst | kubectl apply -f -
```
This bypasses some GKE networking layers and is needed to run workloads with `hostNetwork: false` (the default). *The Terraform module will integate this in the future.*

### Provision and attach a shared NFS file-system

Enable the GCP Filestore driver on your cluster.
```
bash scripts/enable-filestore-driver-on-gke-cluster.sh
```

Then provision and attach a shared Filestore volume of the desired size to your cluster.
```
cat manifests/sharedfs-via-filestore.yaml| envsubst | kubectl apply -f -
```
This step may take 15 or more minutes. You can check the progress of the cluster provisioning by visiting [Cloud Console](https://console.cloud.google.com/filestore/instances). To learn more about the performance about Filestore, see https://cloud.google.com/filestore/docs/service-tiers. *The Terraform module may integate this in the future.*

### Optional: Install Kueue as a batching and administrative system

Install the Kueue batching system. Kueue provides services for workload batching, pre-emption, adminstrative control, and all-or-nothing launch semantics. To learn more about Kueue visit https://kueue.sigs.k8s.io/docs/concepts/.
```
VERSION=v0.5.2 kubectl apply --server-side \
  -f https://github.com/kubernetes-sigs/kueue/releases/download/$VERSION/manifests.yaml
```

The Kueue controller will run on the E2 node pool provisioned earlier. 

After installing the Kueue system, create a single queue named `a3-queue` to which A3 workloads can be submitted.

```
cat manifests/a3-queue-via-kueue.yaml | envsubst | kubectl apply -f -
```

## Workload Setup and Launch

### Optional: Place your custom training data in a GCS bucket

For the purposes of demonstration, we host a pre-tokenized sample of Wikipedia data in a public bucket at `gs://nemo-megatron-demo/training-data/processed/gpt/wikitext`. This dataset was created by following [Collecting Wikipedia Training Data](https://github.com/NVIDIA/Megatron-LM/tree/main?tab=readme-ov-file#collecting-wikipedia-training-data). Note that this is a static snapshot of Wikipedia text captured in the middle of 2023. It is recommended you use this data source on your first workload launch.

If you choose, you can upload your own training data. In our demonstration we invoke NeMo Megatron pre-training for the standard GPT model. Therefore it is expected the dataset is already tokenized and compatible format followed by [Megatron-LM](https://github.com/NVIDIA/Megatron-LM?tab=readme-ov-file#data-preprocessing) for tokenizer type `GPT2BPETokenizer`. 

First create a GCS bucket that will host the training data.
```
gcloud storage buckets create gs://my-training-bucket --location=$REGION
```

Then upload your pre-tokenized training data to it.
```
gcloud storage cp my-training-data.{idx,bin} gs://my-training-bucket
```

Note that in this demonstration the training data cannot exceed the size of the local SSD (i.e. 6 TiB). This limitation is only due to our setup caching the training data to the local SSD on launch. For larger sizes the shared FileStore or [GCF fuse](https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/cloud-storage-fuse-csi-driver) can be used.

### Upload NeMo Megatron Docker image to Artifact registry

For this step you need access to the [NVIDIA Big NLP training](https://registry.ngc.nvidia.com/orgs/ea-bignlp/containers/bignlp-training) Docker images. In particular `nvcr.io/ea-bignlp/nemofw-training:23.05-py3`. Obtain access to these Docker images by registering with NVIDIA. In the future the source of this image may change.

Create an artifact registry that can host the Docker image.
```
bash scripts/create-artifact-registry.sh 
```

Fetch the credentials for your registry
```
gcloud auth configure-docker --registries=$REGION-docker.pkg.dev
```

Now build the Dockerfile and push it to this registry.
```
bash scripts/build-and-push-nemo-training-image.sh
```
Note that the Dockerfile is essentially just `nvcr.io/ea-bignlp/nemofw-training:23.05-py3`. You will not need to modify this Docker image.

### Setup the training and model configuration

The file `nemo-example/selected-configuration.yaml` is a [NeMo Megatron](https://github.com/NVIDIA/NeMo) compatible configuration file. It is by initially soft-linked as follows:
```
selected-configuration.yaml --> nemo-configurations/gpt-5b.yaml
```
On a first attempt we recommend leaving as-is. On later launches, you may review and edit the configuration. See [NeMo Megatron Launcher](https://github.com/NVIDIA/NeMo-Megatron-Launcher/tree/master/launcher_scripts/conf/training) for examples of configurations of alternate models and model sizes.

Before launching the model training, we need to review `nemo-example/values.yaml`:
```
queue: null # optional (must have installed Kueue and pre-provisioned a local queue, see previous guide steps)

volumes:
  ssdMountPath: "/ssd"
  pvcMounts:
  - name: cluster-filestore
    mountPath: "/nfs"
  - name: cluster-gcsfuse
    mountPath: "/gcs"

gcsDownload: # downloads or synchronizes contents of a GCS bucket folder on initialization
  source: "gs://nemo-megatron-demo/training-data/tokenized/bpe2gpt/wikipedia/" 
  target: "/ssd/.cache/"

workload:
  image: "$REGION-docker.pkg.dev/$PROJECT/$PREFIX/nemofw-training:23.05-py3"
  torchDistributedTarget: "/opt/NeMo/examples/nlp/language_modeling/megatron_gpt_pretraining.py"

  gpus: 16 # This should be one of: {<= 8,  multiple of 8}
  arguments: 
  # These argument name will be prefixed with '+' (see https://hydra.cc/docs/advanced/override_grammar/basic/)
  - name: "exp_manager.exp_dir"
    value: "/nfs/nemo-experiments/"
  - name: "model.data.data_prefix"
    value: "[1.0,/ssd/.cache/wikipedia-tokenized-for-gpt2]"

  # If not 'null', launches a Tensorboard server on first node. By design, enabling this will cause the job to not exit on the first node!
  # This is primarly intended for debugging (e.g. when a shared file-system and/or alternative Tensorboard is unavailable).
  # You can view this Tensorboard on your local host with `kubectl port-forward <first-pod-name> 6006:6006` and visiting `localhost:6006` in your browser.  
  embeddedTensorboardTarget: null
```

If you deployed  

### Launch NeMo Megatron training

Launch the GPT model training across the desired node scale.
```
cat nemo-example/values.yaml | envsubst \
  | helm install --set workload.nodes=2 $USER-nemo-$(date +%s) -f - nemo-example/
```

Verify the launch succeeded by seeing the corresponding pods in `Running` state. 
```
$ kubectl get pods
```

This may take a few minutes the first time it is executed.

## Create a Tensorboard endpoint to view the training

In this section we demonstrate how to deploy a Tensorboard endpoint that can be accessed by a browser on any host that is logged into, and has the relevant permissions, for the associated project. For this step it is necessary that you did **not** enable Workload Identity on your GKE cluster. *The security boundaries will be improved in the future.*

Deploy the Tensorboard and inverse-proxy to your GKE cluster.
```
kubectl apply -f tensorboard-endpoing/tensorboard.yaml
```

Wait for both the inverse-proxe and tensorboard pods to go `Running`. 

Then find the corresponding URL endpoint for Tensorboard.
```
kubectl describe configmap inverse-proxy-config
```
If successful, the URL corresponds to the `Hostname` field. You can visit this URL in your browser and should see the Tensorboard page.