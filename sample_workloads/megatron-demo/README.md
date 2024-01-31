# Megatron on GKE

### Prerequisites

- Gcloud Cli
- Terraform
- Helm
- Kubectl
- A3 quota

### Provision GKE cluster
```
terraform init && terraform apply
```
This leverages the AI cluster provisioning tool to provision the following resources:
1. Regional GKE cluster with A3 VMs (todo: Make it zonal)
2. Five VPCs, one per NIC.

Internal notes: 
1. Bug: The default node pool is missing and needs to be added back in! Need to specify its VM type
2. Bug: The tool has a bug that causes conflict of service, pod IP ranges in VPC.
3. Todo: The tool should optionally enable GCS fuse driver for GKE.
4. Todo: The tool does not apply the network pass-through mode.
5. Todo: The non-beta version is unable to apply the PERIODIC maintenance interval.
6. Todo: Is it necessary to create a non-default service account?

### Optional (Recommended): Install Kueue batching system

```
VERSION=v0.5.2
kubectl apply --server-side -f https://github.com/kubernetes-sigs/kueue/releases/download/$VERSION/manifests.yaml

kubectl create -f a3-queue-via-kueue.yaml
```

Kueue enables workload batching, adminstrative control, and all or nothing semantics.

Internal Notes:
1. It is necessary to adjust the nominalQuota to GPUs available!
2. Describe the usefulness of Kueue, the various concepts (with diagram)
3. Describe the drawbacks of Kueue.

### Optional (Recommended): Connect a shared NFS file-system

```
gcloud \
  container clusters update <your-gke-cluster> \
  --update-addons=GcpFilestoreCsiDriver=ENABLED \
  --project <your-gke-cluster-project> \
  --zone <your-gke-cluster-zone>

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

### Launch NeMo GPT-5B example

```
cd nemo-example
```

The `selected-configuration.yaml` is soft-linked to one of the configurations in `nemo-configuration/`. Adjust this as necessary.

Launch the NeMo workload
```
helm install --set workload.nodes=2 $USER-nemo-$(date +%s) . 
```

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
