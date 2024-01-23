# Megatron on GKE


1) Provision cluster via Terraform using main.tf (follow-up with Cillium fix)
"terraform init && terraform apply on GKE (not beta)"
Notes (create a bug for each of these):
 - Missing default node pool
 - Created as a regional cluster (instead of zonal)
 - Traditional cillium fix is not applied

2) Setup a shared NFS drive for the cluster (one-liner)
"gcloud container clusters update CLUSTER_NAME --update-addons=GcpFilestoreCsiDriver=ENABLED"
"kubectl apply -f sharedfs-via-filestore.yaml"
Notes: 
 - Need to enable Filestore CSI driver on the GKE cluster first
   (This appears to take 10+ minutes to enable.)
 - The "network:" value needs to be equal to the resource prefix
 - The name of the PVC and the size of the NFS storage needs to be specified
   (The NFS provisioning appears to take about 15+ min.)
 
3) Install Kueue system (one-liner)
"kubectl create -f kueue-system-v0.5.1.yaml"

Notes:
 - Don't use "kubectl apply -f" for the first command.
 - You need to make sure the default node pool isn't an "e2-medium" or other small machine.
 - The CustomResourceDefinition "workloads.kueue.x-k8s.io" is invalid: metadata.annotations: Too long: must have at most 262144 bytes

4) Setup a single A3 queue.
"kubectl apply -f a3-queue-via-kueue.yaml"

Notes:
 - You need to wait a few seconds before creating the queue.

5) Run the generic PyTorch all-reduce example using NVIDIA PyTorch + TCPx
"helm install sufkha-pytorch-$(date +%s) ."

Notes:



6) Run the generic PyTorch via MPI example using NVIDIA PyTorch + TCPx
7) Instructions to populate training data
8) Run NeMo Megatron for GKE (a minimal adaptation on #5 or #6)

FAQ/Troubleshooting)
- Version matrix support (e.g. latest NCCL is no longer compatible)
- COS version is tied to the GKE version (and -109 is not compatible)
- Why do I see TX or RX timeouts?



SUFFIAN INTERNAL NOTES:

Internal GKE creation:
1) Creates a service account that user can impersonate and pin to resources. Gives it GKE cluster admin permissions. 
sufkha Q: What is the value of this?
2) Create five VPCs, enable outbound IPv6 and allow all internal TCP/UDP connections within the subnets.
3) Create an empty GKE zonal cluster by impersonating the GSA from step 1. Multiple features are toggled on/off. NIC0 VPC is attached. Pod and Service IP ranges are set. Cannot conflict with the existing subnet ranges. The IP ranges should be large enough to accomodate many nodes.
4) Install GPU drivers (apply the "fix-up" daemonset yaml) and then applies a pinned COS GPU installer.
sufkha Q: Why is the "fix-up" daemonset needed? Was it a temporary workaround that we can drop?
5) Apply the "cillium" fix by using an existing .yaml (some net and subnet names are substituted)
sufkha Q: Is the "cillium" fix a temporary workaround that we can drop? If not, when can we?
6) Creates a resource policy with compact placement (a single SB)
sufkha Q: Is this easy enough to enable/disable?
7) Creates node pool (w/ local SSD), full GCP API scope, attached 4 VPCs, gVNIC, restricted pods per node (32), placement policy specified, disable auto-upgrade/repaire. If needed, sets a custom COS image (requires project feature flag enabled).
sufkha Q: Is there any way to control the COS version apart from the GKE version? Will whale customers have instructions for custom images?
8) Installs the health runner.

External GKE creation:
1) Does it use the default service account?
2) Specifies workload identity and performs a binding of k8s service account to default service account.
sufkha Q: What does the workload identity enable?
3) Instead of impersonating service account on creation it uses default application credentials.
4) The gke-beta is somewhat outdated compared to gke?
5) Will the host maintenance interval be supported in gke/ soon? What is the ETA?

Agenda:
1) Provision a 2-node GKE cluster (and then resize it)
2) Install a shared-file system (as before)
3) Install kueue and kubeflow integration
4) Run a succesful MPI example job
5) Run a NCCL test using MPI launcher
6) Run Megatron-LM using MPI launcher

Notes:
1) Authorize Terraform
```
gcloud auth application-default login
```
2) Terraform init & Terraform apply
Sub-notes: 
- The cluster is zonal and the default pool is small (adjustable?)
- Unable to SSH from cloudtop to nodes that came up (missing firewall rule)
- Unable to SSH from one node to another (maybe okay)
- Do we need the firewall rules provided by create-network.sh?
- NVIDIA driver is installed at 535.104.12
- COS version at cos-109-17800-66-19 (Nov 07, 2023)
- You need to manually create the GCS bucket before `terraform init`

Try again with GKE-beta
- Is it not possible to create a zonal cluster? Tool needs more flexibility
- Additional Node Interface CIDR range 10.4.0.0/19 overlaps with existing range 10.4.0.0/14.
- What control does a user have to select an "LKG" COS version?
- The destroy command did not work under some circumstance.
- Setting GKE version 1.27.8-gke.1067000 got the expected COS.
- Is it possible to "merge" gke/ and gke-beta/?

In this tutorial we demonstrate running NeMo Megatron and Megatron-LM on GKE.

1) Setup GKE cluster (use provisioning tool). By the end of this setup we want a cluster with N nodes with X GB of persistent disk, multi-VPC networking, NVIDIA drivers installed, and fixes applied, and a shared-filesystem (if desired).

Installing a shared file-system:
https://cloud.google.com/filestore/docs/csi-driver#create
```
gcloud --project supercomputer-testing container clusters update daily-run-single-zone-gker26 --update-addons=GcpFilestoreCsiDriver=ENABLED --zone us-central1-c

kubectl create -f filestore-example-class.yaml
kubectl create -f pvc-example.yaml
kubectl apply -f filestore-example-deployment.yaml
```

The GKE cluster update command can take 10 min! The NFS provision can take 15+ min!

2) Install kueue for job orchestration.
https://kueue.sigs.k8s.io/docs/installation/

```
VERSION=v0.5.1
wget https://github.com/kubernetes-sigs/kueue/releases/download/$VERSION/manifests.yaml

kubectl apply --server-side -f manifests.yaml
```

3) Install JobSet extension
VERSION=v0.3.1
kubectl apply --server-side -f https://github.com/kubernetes-sigs/jobset/releases/download/$VERSION/manifests.yaml

- The latest Kueue + latest Jobset do not appear to work together. It's not clear if we really need jobset anyway.
- It's also unclear the value add of Kueue. Helm is still needed due to its simplicity and mustache notation.

Install MPI operator
```
kubectl apply -f https://raw.githubusercontent.com/kubeflow/mpi-operator/v0.4.0/deploy/v2beta1/mpi-operator.yaml
```

