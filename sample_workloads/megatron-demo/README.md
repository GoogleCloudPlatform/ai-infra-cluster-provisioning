# NeMo Megatron on GKE

This document demonstrates running [NeMo Megatron](https://github.com/NVIDIA/NeMo) on A3 VMs in a GKE environment usng TCPx technology. The A3 VMs have 8x NVIDIA H100 GPUs and 4x 200 Gbps NICs and leverage TCPx for direct GPU to NIC transfers.

### Prerequisites

- [Gcloud Cli](https://cloud.google.com/sdk/docs/install)
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/install-cli)
- [Helm](https://helm.sh/docs/intro/install/)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)

In addition to the above tools, you will need quota for: 
- NVIDIA H100 GPUs
- Cloud FileStore Enterprise (optional)

## Infrastructure Setup

### Select project, zone, and resource prefix
Adjust the values in `set-enviroment.sh` to suit your case:
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
*The prefix `TF_VAR_` exposes the variables to Terraform. Take note that some variables are still used by non-Terraform commands below.*

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

Add a node pool with the desired count of E2 VMs in your GKE cluster in order to host system services (e.g. DNS pods, custom controllers). *The Terraform module will integate this in the near future.*
```
bash scripts/create-e2-node-pool.sh 
```
 
### Optional: Install Kueue as a batching and administrative system

Install the Kueue batching system. Kueue enables workload batching, pre-emption, adminstrative control, and all-or-nothing launch semantics. To learn more about Kueue visit https://kueue.sigs.k8s.io/docs/concepts/.
```
VERSION=v0.5.2 kubectl apply --server-side \
  -f https://github.com/kubernetes-sigs/kueue/releases/download/$VERSION/manifests.yaml
```

The Kueue controller will run on the E2 node pool provisioned earlier. After installing the Kueue system, create a single queue `a3-queue` to which A3 workloads can be submitted.

```
kubectl create -f a3-queue-via-kueue.yaml
```


### Optional: Provision and attach a shared NFS file-system

Enable the GCP Filestore driver are your cluster.
```
gcloud \
  container clusters update <your-gke-cluster> \
  --update-addons=GcpFilestoreCsiDriver=ENABLED \
  --project <your-gke-cluster-project> \
  --zone <your-gke-cluster-zone>
```

Provision an Filestore volume 
```
kubectl create -f sharedfs-via-filestore.yaml
```

Internal Notes:
1. It is necessary to set the correct GKE eth0 network.
2. It is necessary to set the desired NFS storage size.
3. Todo: Integrate this into the AI provisioning tool.
4. This step takes approximately 15 minutes to execute.
5. Enterprise NFS storage quota not available out of the box.
6. NFS enterprise performance at

https://cloud.google.com/filestore/docs/service-tiers
Read 120 MiB/s per 1 TiB of provisioned capacity
Write 100 MiB/s per 1 TiB of provisioned capacity

Compare to Google Cloud storage
https://cloud.google.com/storage/quotas
Ostensibly 200 Gbps (but can be increased)

## Workload Setup and Launch

### Optional: Place your custom training data in a GCS bucket

Create a GCS bucket and upload your training data to it:
```
bash scripts/upload-training-data-to-new-gcs-bucket <bucket-name> <>
```

In our demonstration we invoke NeMo Megatron pre-training for the standard GPT model and it is expected the dataset is pre-tokenized for BPE and compatible with tokenization followed by [Megatron-LM](https://github.com/NVIDIA/Megatron-LM?tab=readme-ov-file#data-preprocessing) for tokenizer type `GPT2BPETokenizer`. Note that in this demonstration the training data cannot exceed the size of the local SSD (i.e. 6 TiB). This is due to the training data being cached in the local SSD on launch. *

For the purposes of demonstration, we host a pre-tokenized version of the Wikipedia data in a public bucket at `gs://...`. It is recommended you use data source on your first workload launch.

### Launch NeMo Megatro GPT-5B example

The file `selected-configuration.yaml` is by default soft-linked to `nemo-configurations/gpt-5b.yaml`. On a first attempt we recommend leaving this as-is. On later launches, you may review and edit the configuration.

Consider how many nodes you expect to launch NeMo Megatron GPT across. On a first launch, we suggest running the GPT-5B model across 2 nodes. Then launch the NeMo Megatron GPT workload using helm.
```
helm install --set workload.nodes=2 $USER-nemo-$(date +%s) . 
```

Verify the launch succeeded 

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
