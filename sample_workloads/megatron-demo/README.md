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
- Quota Cloud FileStore Enterprise (this is optional)
- Access to [NVIDIA NGC Big NLP Training](https://registry.ngc.nvidia.com/orgs/ea-bignlp/containers/bignlp-training) Docker images

## Infrastructure Setup

### Select project, zone, and resource prefix
Adjust the values in `set-enviroment.sh` to suit your case.
```
export TF_VAR_PROJECT=<your-project-name>
export TF_VAR_PREFIX=nemo-megatron-demo
export TF_VAR_REGION=us-central1
export TF_VAR_ZONE=us-central1-c

export TF_VAR_A3_NODE_COUNT=2
export TF_VAR_E2_NODE_COUNT=4
export TF_VAR_NFS_SIZE="1Ti"
```
The E2 nodes are used for system services (e.g. DNS pods, custom controllers).
*The prefix `TF_VAR_` exposes the variables to Terraform. Take note that some of these environment variables are still used by non-Terraform commands below.*

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
  -backend-config="bucket=$TF_VAR_PREFIX" \
  -backend-config="prefix=$TF_VAR_PREFIX"
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

### Adjust GKE networking such that the VPCs are in device mode

Adjust GKE networking to place the VPCs in device mode.
```
cat manifests/enable-network-pass-through.yaml | envsubst | kubectl apply -f -
```
This bypasses some GKE networking layers and is needed to run workloads with `hostNetwork: false` (the default). *The Terraform module will integate this in the future.*

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

### Optional: Provision and attach a shared NFS file-system

Enable the GCP Filestore driver on your cluster.
```
bash scripts/enable-filestore-driver-on-gke-cluster.sh
```

Then provision and attach a shared Filestore volume of the desired size to your cluster.
```
cat manifests/sharedfs-via-filestore.yaml| envsubst | kubectl apply -f -
```
This step may take 15 or more minutes. You can check the progress of the cluster provisioning by visiting [Cloud Console](https://console.cloud.google.com/filestore/instances). To learn more about the performance about Filestore, see https://cloud.google.com/filestore/docs/service-tiers. *The Terraform module may integate this in the future.*


## Workload Setup and Launch

### Optional: Place your custom training data in a GCS bucket

For the purposes of demonstration, we host a pre-tokenized version of the Wikipedia data in a public bucket at `gs://nemo-megatron-demo/training-data/processed/gpt/wikitext`. This dataset was created by following [Collecting Wikipedia Training Data](https://github.com/NVIDIA/Megatron-LM/tree/main?tab=readme-ov-file#collecting-wikipedia-training-data). It is recommended you use this data source on your first workload launch.

If you choose, you can upload your own training data. In our demonstration we invoke NeMo Megatron pre-training for the standard GPT model. Therefore it is expected the dataset is already tokenized and compatible format followed by [Megatron-LM](https://github.com/NVIDIA/Megatron-LM?tab=readme-ov-file#data-preprocessing) for tokenizer type `GPT2BPETokenizer`. 

First create a GCS bucket that will host the training data.
```
gcloud storage buckets create gs://my-training-bucket --location=$REGION
```

Then upload your pre-tokenized training data to it.
```
gcloud storage cp my-training-data.{idx,bin} gs://my-training-bucket
```

Note that in this demonstration the training data cannot exceed the size of the local SSD (i.e. 6 TiB). This limitation is only due to our setup caching the training data to the local SSD on launch. For larger sizes the shared file-system or [GCF fuse](https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/cloud-storage-fuse-csi-driver) can be used.

### Upload NeMo Megatron Docker image to Artifact registry

For this step you need access to the [NVIDIA Big NLP training](https://registry.ngc.nvidia.com/orgs/ea-bignlp/containers/bignlp-training) Docker images. In particular `nvcr.io/ea-bignlp/nemofw-training:23.05-py3`. Obtain access to these Docker images by registering with NVIDIA. In the future the source of this image may change.

Create an artifact registry that can host the Docker image.
```
bash scripts/create-artifact-registry.sh 
```

Fetch the credentials for your registry
```
docker-credential-gcr configure-docker --registries=$REGION
```

Now build the Dockerfile.
```
docker build \
  -f nemo-example/docker/nemo_example.Dockerfile
  -t $REGION-docker.pkg.dev/$PROJECT/$PREFIX:nemofw-training:23.05-py3
  nemo-example/docker
```
Note that the Dockerfile is essentially just `nvcr.io/ea-bignlp/nemofw-training:23.05-py3`.

Push the Docker image to the artifact registry.
```
docker push $REGION-docker.pkg.dev/$PROJECT/$PREFIX
```

You will not need to modify this Docker image.

### Setup the training and model configuration

The file `nemo-example/selected-configuration.yaml` is a [NeMo Megatron](https://github.com/NVIDIA/NeMo) compatible configuration file. It is by initially soft-linked as follows:
```
selected-configuration.yaml --> nemo-configurations/gpt-5b.yaml
```
On a first attempt we recommend leaving as-is. On later launches, you may review and edit the configuration. See [NeMo Megatron Launcher](https://github.com/NVIDIA/NeMo-Megatron-Launcher/tree/master/launcher_scripts/conf/training) for examples of configurations of alternate models and model sizes.

Before launching the model training, we need review `nemo-example/values.yaml`:
```
workload:
  nodes: 2                
  image: "$REGION-docker.pkg.dev/$PROJECT/$PREFIX:nemofw-training:23.05-py3"                                         
  torchRunTarget: "/opt/NeMo/examples/nlp/language_modeling/megatron_gpt_pretraining.py"                               
  trainingDataSource: "gs://megatron-data-us/training-data/wikitext"
```

### Launch NeMo Megatron training

Launch the GPT model training across the desired node scale.
```
helm install --set workload.nodes=2 $USER-nemo-$(date +%s) nemo-example/ 
```

Verify the launch succeeded by seeing the corresponding pods in `Running` state. This may take a few minutes the first time it is executed.
```
$ kubectl get pods
```

### Watch the training step time and loss curves


Install Tensorboard and the inverse proxy
```
kubectl apply -f tensorboard.yaml
```

Find the corresponding URL endpoint for Tensorboard
```
kubectl describe configmap inverse-proxy-config
```
If successful, the URL corresponds to the `Hostname` field.

Internal Notes:
1. The tensorboard and inverse proxy to move onto the job itself.
2. The inverse proxy doesn't work with non-default service account specified by AI provision tool.
