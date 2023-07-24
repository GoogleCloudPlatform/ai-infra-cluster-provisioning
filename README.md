# Table of Contents
1. [Overview](#overview)
    1. [Purpose](#purpose)
    1. [Description](#description)
1. [Types of Clusters](#types-of-clusters)
    1. [A3 Clusters](#a3-clusters)
    1. [Other Clusters](#other-clusters)
1. [How to create a cluster](#how-to-create-a-cluster)
    1. [Run the docker image](#run-the-docker-image)
    1. [Integrate into an existing terraform project](#integrate-into-an-existing-terraform-project)
    1. [Integrate into an existing HPC Toolkit Blueprint](#integrate-into-an-existing-hpc-toolkit-blueprint)

# Overview

## Purpose

The purpose of this tool is to provide a very quick and simple way to provision
a compute cluster on Google Cloud Platform (GCP).

## Description

This repository contains:
- a set of terraform modules that creates GCP resources geared toward running
  AI/ML workloads on [A3 VMs](#a3-clusters).
- an [entrypoint script](./scripts/entrypoint.sh) that will find or create a
  terraform backend in a Google Cloud Storage (GCS) bucket, call the
  appropriate terraform commands using the terraform modules and a user
  provided terraform variables (`tfvars`) file, and upload all logs to the GCS
  backend bucket.
- a [docker image](./Dockerfile) --
  `us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image`
  -- that has all necessary tools installed which calls the entrypoint script
  and creates a cluster for you.

# Types of clusters

## A3 Clusters

An A3 cluster provides the following resources:
- one or many a3-highgpu-8g VM instances (full documentation not available yet,
  description
  [here](https://cloud.google.com/blog/products/compute/introducing-a3-supercomputers-with-nvidia-h100-gpus)).
- five virtual network interface cards (vNIC) -- two H100 GPUs connected to each vNIC.
- [Nvidia GPUDirect](https://developer.nvidia.com/gpudirect).

In the future, any of the [other clusters](#other-clusters) may be an A3 cluster by setting these two variables in the `tfvars` file:
```terraform
machine_type = "a3-highgpu-8g"
network_config = "new_multi_nic"
```

However, due to their recency, A3 clusters are supported by only:
- [`mig-with-container`](./terraform/modules/cluster/mig-with-container): a
  [Managed Instance Group (MIG)](https://cloud.google.com/compute/docs/instance-groups#managed_instance_groups)
  of instances booting with a
  [COS-Cloud image](https://cloud.google.com/container-optimized-os/docs).

## Other Clusters

Clusters of non-A3 machines may be created just as easy as those with A3
machines though it is recommended to use A3 machines in order to acheive
maximum performance. These cluster types are:
- [`gke`](./terraform/modules/cluster/gke):
  [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine)
  cluster of instances booting with a
  [COS-Cloud image](https://cloud.google.com/container-optimized-os/docs).
- [`mig`](./terraform/modules/cluster/mig):
  [Managed Instance Group (MIG)](https://cloud.google.com/compute/docs/instance-groups#managed_instance_groups)
  instances booting with a user-decided
  [VM image](https://cloud.google.com/compute/docs/images)
- [`slurm`](./terraform/modules/cluster/slurm):
  [Slurm](https://slurm.schedmd.com/documentation.html) cluster of instances
  booting with a
  [SchedMD Slurm VM image](https://github.com/SchedMD/slurm-gcp/blob/master/docs/images.md#published-image-family).

# How to create a cluster

You will need:
- a GCP project with GCE API enabled.
- a GCP account with IAM role
  [`roles/editor`](https://cloud.google.com/iam/docs/understanding-roles#basic).
- [`gcloud` authorization](https://cloud.google.com/sdk/docs/authorizing) --
  you should be able to run `gcloud auth list` and see your account.

There are a few ways to create a cluster:
1. Run the docker image: do this if you don't have any existing infrastructure
  as code.
1. Integrate into an existing terraform project: do this if you already have
  (or plan to have) a terraform project and would like to have the same
  `terraform apply` create this cluster along with all your other
  infrastructure.
1. Integrate into an existing HPC Toolkit Blueprint: do this if you already have
  (or plan to have) an HPC Toolkit Blueprint and would like to have the same
  `ghpc deploy` create this cluster along with all your other infrastructure.

## Run the docker image

For this method, all you need (in addition to the above requirements) is a
`terraform.tfvars` file (user generated or copied from an [example](./examples)) in your
current directory and the ability to run [docker](https://www.docker.com/). In
a terminal, change your current working directory to this one and run the command:
```bash
# create/update the cluster
docker run \
  --rm \
  -v "${HOME}/.config/gcloud:/root/.config/gcloud" \
  -v "${PWD}:/root/aiinfra/input" \
  us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest \
  create mig-with-container

# destroy the cluster
docker run \
  --rm \
  -v "${HOME}/.config/gcloud:/root/.config/gcloud" \
  -v "${PWD}:/root/aiinfra/input" \
  us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest \
  destroy mig-with-container
```

Quick explanation of the `docker run` flags (in same order as above):
- `-v "${HOME}/.config/gcloud:/root/.config/gcloud"` exposes gcloud credentials
  to the container so that it can access your GCP project.
- `-v "${PWD}:/root/aiinfra/input"` exposes the current working directory to
  the container so the tool can read the `terraform.tfvars` file.
- `create/destroy` tells the tool whether it should create or destroy the whole
  cluster.
- `mig-with-container` tells the tool to create a Managed Instance Group and
  start a container at boot. Descriptions of clusters may be found
  [above](#types-of-clusters).

## Integrate into an existing terraform project

For this method, you need to
[install terraform](https://developer.hashicorp.com/terraform/downloads).
Examples of usage as a terraform module can be found in the `main.tf` files in
any of the directories found [here](./examples/a3). Cluster provisioning then
happens the same as any other terraform:
```bash
# assuming the directory containing main.tf is the current working directory

# create/update the cluster
terraform init && terraform validate && terraform apply

# destroy the cluster
terraform init && terraform validate && terraform apply -destroy
```

## Integrate into an existing HPC Toolkit Blueprint

For this method, you need to
[build ghpc](https://github.com/GoogleCloudPlatform/hpc-toolkit#quickstart).
The `a3-mig-with-container` deployment group in the `blueprint.yaml` shows how
to use the `mig-with-container` module in your HPC Toolkit Blueprint. Cluster
provisioning then happens the same as any blueprint:
```bash
# assuming the ghpc binary and blueprint.yaml are both in
# the current working directory

# create/update the cluster
./ghpc create -w ./blueprint.yaml && ./ghpc deploy a3-mig-with-container

# destroy the cluster
./ghpc create -w ./blueprint.yaml && ./ghpc destroy a3-mig-with-container
```

---
---
### Old docs
---
---


## Configuration for Users

Users can use the cluster provisioning tool to create GPU clusters in few different
ways. They are Managed instance groups (MIGs), Google kubernetes engine (GKE) and
Slurm. The configurations are different for different type of GPU clusters.
1. The configurations for a GPU cluster using
   [MIG are here](./terraform/modules/cluster/mig/README.md). An example of a simple GPU
   cluster using MIG can be found [here](./samples/mig/simple/terraform.tfvars).
1. The configurations for a GPU cluster using
   [MIG with Containers are here](./terraform/modules/cluster/mig-with-container/README.md). An example of a simple GPU
   cluster using MIG-with-container can be found [here](./samples/mig-with-container/simple/terraform.tfvars).
1. The configurations for a GPU cluster using
   [GKE are here](./terraform/modules/cluster/gke/README.md). An example of a simple GPU
   cluster using GKE can be found [here](./samples/gke/simple/terraform.tfvars).
1. The configurations for a GPU cluster using
   [GKE-beta are here](./terraform/modules/cluster/gke-beta/README.md). An example of
   a a3 multi-NIC GPU
   cluster using GKE-beta can be found [here](./samples/gke-beta/a3_multiNIC_network/README.md).
2. The configurations for a GPU cluster using
   [Slurm are here](./terraform/modules/cluster/slurm/README.md). An example of a simple GPU
   cluster using Slurm can be found [here](./samples/slurm/minimal/terraform.tfvars).

For more complex GPU clusters, please use examples from [this section
below](#samples-for-use-cases). 

# Usage
The cluster provisioning tool can be used in 3 different ways.
1. [Docker image](#usage-via-docker-image) : The cluster provisioning tool public
   image can be used with `docker run` command to execute the tool in a docker
   container to create a GPU cluster.The target audience are: 
   * The users who want to run the tool manually as a client tool and looking for 
   easy setup and quick turn around time to create the cluster. 
   * The service with docker integration to create containers that wants to provision
   a GPU cluster automatically. 
2. [Terraform module](#usage-via-terraform) : The cluster provisioning tool module
   can be used with `terraform` to create a GPU cluster. The target audience are:
   * The users who has existing terraform scripts and want to integrate GPU cluster 
   creation to it.
   * The service that uses terraform to create resources and wants to integrate GPU
   cluster creation to it.
   * The CI/CD pipeline that uses terraform to manage resources and wants to create a
   GPU cluster via the pipeline.
3. [HPCToolkit module](#usage-via-hpctoolkit) : The cluster provisioning tool module
   can be used with `HPCToolkit` to create a GPU cluster. The target audience are:
   * The users who are familiar with HPC toolkit and want to integrate GPU cluster
   creation to their existing HPC toolkit blueprint.

## **Usage via Docker image**

The user updates the `terraform.tfvars` file in their current working location and
runs the docker image with this file to create resources using the ‘docker run’
command. As part of the run command, users
have to specify an action and a cluster. The action can be `create` or `destroy`. The
cluster can be `mig`, `gke`, `gke-beta` or `slurm`. The sample command looks like

#### docker command:
```docker
docker run -it -v ${PWD}:/root/aiinfra/input us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest create mig

docker run -it -v ${PWD}:/root/aiinfra/input us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest destroy mig
```
All the setup needed before calling terraform to create resources is handled by
entrypoint.sh script. This is packaged in the docker image and gets executed when the
container starts. It uses the `terraform.tfvars` file
in the current working directory, which is mounted via the `docker run` command to
call terraform and create the resources. 

### **User Authentication**

The cluster provisioning tool interacts with GCP to create cloud resources on behalf
of the user. So for doing that it needs the user’s authentication token with GCP.
There are 3 environments where we expect the cluster provisioning tool to run. They
are

1. **Cloud shell**: In the cloud shell environment, the default cloud authentication
   token is available that cluster provisioning tool uses for resource creation. No
   additional action is needed from the user. 
2. **User machine with gcloud authentication**: In the case where the user is running the
   cluster provisioning tool on their machine, they need to be authenticated with GCP
   for resource creation. There are 2 ways to do this.
   - Running ‘gcloud auth application-default login’ and mounting the local gcloud
     config to the container. For that use the [`docker run`](#docker-command) command with option `-v
     ~/.config/gcloud:/root/.config/gcloud` for Linux or option `-v
     C:\Users\%username%\AppData\Roaming\gcloud:/root/.config/gcloud` for windows.
   - Simply run the container image using [`docker run`](#docker-command). When the cluster provisioning
     tool does not find any default authentication token it asks for manual
     authentication. Follow the prompt and provide the authorization code. The
     authorization prompt looks like below which is the same as gcloud authorization
     prompt.
     ```
     No authenticated account found.
     Go to the following link in your browser:

     https://accounts.google.com/o/oauth2/auth?......

     Enter authorization code: 4/0xxxxxxxx

     Application default credentials (ADC) were updated.

     You are now logged in as [username@google.com].
     ```

3. **LLM pipeline**: LLM pipeline uses VMs to run the cluster provisioning tool and the
   VM has default cloud authentication token available. So additional authentication
   is not needed here.


### **State management across sessions**

When terraform is executed to create the resources, it creates state files to keep
track of the created resources. While changing or destroying resources, terraform
uses these state files. If these state files are created within the container, then
they will be lost when the container exits. That will result in leaking of the
resources. Having the state files in the container forces cleanup resources before
the container exits. This ties the cluster lifespan to that of the container. 

So to have better control over the resources we need to have the state files managed in
cloud storage. That way multiple runs of the container can use the same state files
to manage the resources. Using the provisioning tool the user can provide a GCS
bucket path for managing the terraform state and
sets it as the backend for terraform. If the user does not provide a GCS bucket path
then the provisioning tool creates a GCS bucket for managing terraform state, but for
this the user needs to have permission to create a GCS bucket in the project they are
using. For that use the [`docker run`](#docker-command) command with option `-b
gs://bucketName/dirName` at the end of the command.

Example:
```docker
docker run -it -v ${PWD}:/root/aiinfra/input us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest create mig -b gs://bucketName/dirName

docker run -it -v ${PWD}:/root/aiinfra/input us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest destroy mig -b gs://bucketName/dirName
```

### **Copying AI/ML training script to the GPU cluster**

The preferred method is via
[GCSFuse](https://cloud.google.com/storage/docs/gcs-fuse). Users can simply
provide their GCS
bucket where they can store training scripts and data in the `terraform.tfvars` file.
Cluster provisioning tool will mount the GCS bucket in the VM as a local volume using
GCSFuse.

For GKE based GPU clusters, the GCS bucket needs to be mounted during POD creation
time. The instructions for that can be found
[here](https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/cloud-storage-fuse-csi-driver#prepare-mount).

### **Multi-node training**

1. For the GPU clusters created via MIG, the cluster provisioning tool provides
   configuration to setup
   [Ray](https://docs.ray.io/en/latest/ray-overview/getting-started.html) as
   orchestrator to create a multi node AI/ML job. It also provides
   configuration to setup
   [multi-NIC](https://cloud.google.com/vpc/docs/create-use-multiple-interfaces) for
   multi node training on MIG.
2. For the GPU clusters created via GKE, GKE can be used for [multi node
   training](https://cloud.google.com/kubernetes-engine/docs/how-to/gpus-multi).
3. Multi node distribute AI/ML workload can also be executed using a GPU cluster
   created via [Slurm](https://slurm.schedmd.com/quickstart.html).

### **Shared Filesystem**

For sharing data across machines running AI workload, users can use a shared file
system. Currently we are using NFS filestore or GCS bucket as shared file system
across machines. Please check the configurations on how to use those.

### **Resource cleanup**

Since the resource state is stored outside of the container, the GPU cluster lifespan
is decoupled from the container’s lifespan. Now the user can run the container and
provide ‘create’ as part of the [`docker run`](#docker-command) command to create the resources. They
can run the container again and provide ‘destroy’ to destroy the container. The
terraform state stored in the GCS bucket is cleared when the destroy operation is
called.

### **Instructions**

1. gcloud auth application-default login.
2. Create `terraform.tfvars` file. The sample `terraform.tfvars` can be found
   [here](./samples/mig/simple/terraform.tfvars). 
3. ***[`HELP`]*** 
   ```docker
   docker run -it -v ${PWD}:/root/aiinfra/input \
     us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest \
     -h
   ```
4. ***[`SIMPLE CREATE`]*** 
   ```docker
   docker run -it -v ${PWD}:/root/aiinfra/input \
     us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest \
     create mig
   ```
5. ***[`SIMPLE DESTROY`]*** 
   ```docker
   docker run -it -v ${PWD}:/root/aiinfra/input \
     us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest \
     destroy mig
   ```
6. ***[`OPTIONAL - Pull docker image before hand`]*** 
   ```docker
   docker pull \
     us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest
   ```
7.  ***[`OPTIONAL - Mount gcloud config for auth token`]*** 
    > `Linux` 
    ```docker
    docker run -it -v ${PWD}:/root/aiinfra/input \
      -v ~/.config/gcloud:/root/.config/gcloud \
      us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest \
      create mig
    ```
    
    > `Windows` 
    ```docker
    docker run -it -v ${PWD}:/root/aiinfra/input \
      -v C:\Users%username%\AppData\Roaming\gcloud:/root/.config/gcloud \
      us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest \
      create mig
    ```
8. ***[`OPTIONAL - GCS bucket not provided`]*** 
    > Need storage object owner access if you don't already have a storage bucket to
    > reuse.
    ```docker
   docker run -it -v ${PWD}:/root/aiinfra/input \
     us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest \
     create mig -b gs://bucketName/dirName
   ```

## **Usage via Terraform**
The user can use the [aiinfra-cluster module from the cluster provisioning tool
GitHub
repository](https://github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning/tree/rework/terraform/modules/cluster).
It can be done by simply providing the source like below.

```terraform
module "aiinfra-mig" {
  source             = "github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning//terraform/modules/cluster/mig"
}
```

```terraform
module "aiinfra-gke" {
  source             = "github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning//terraform/modules/cluster/gke"
}
```

```terraform
module "aiinfra-slurm" {
  source             = "github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning//terraform/modules/cluster/slurm"
}
```

An example terraform config using the aiinfra-cluster module can be found
[here](./samples/mig/simple/main.tf). For more complex use cases please find the
example in the [section below](#samples-for-use-cases).

#### **Cloud credentials on your workstation**

You can generate cloud credentials associated with your Google Cloud account using
the following command:

```shell
gcloud auth application-default login
```

You will be prompted to open your web browser and authenticate to Google Cloud and
make your account accessible from the command-line. Once this command completes,
Terraform will automatically use your "Application Default Credentials."

If you receive failure messages containing "quota project" you should change the
quota project associated with your Application Default Credentials with the following
command and provide your current project ID as the argument:

```shell
gcloud auth application-default set-quota-project ${PROJECT-ID}
```

### **State management across sessions**

Terraform creates state files to track the state of the resources created. The state
files are created on local machine. terraform depends on those state files to manage
the resources. When the states files are created on local machine, it cannot be
shared by multiple users, so only one user can manage the resources. So to enable
multiple users to manage the GPU cluster from different machines, the states needs to
be stored outside the local machines. For that, a `backend.tf` file needs to be
created. More details on that can be found
[here](https://developer.hashicorp.com/terraform/language/settings/backends/gcs). For
example of using GCS bucket as backend with terraform please check
[here](./samples/mig/complex_default_network_backend/).

### **Terraform Deployment Troubleshooting**

When `terraform apply` fails, Terraform generally provides a useful error message.
Here are some common reasons for the deployment to fail:

* **GCP Access:** The credentials being used to call `terraform apply` do not have
  access to the GCP project. This can be fixed by granting access in `IAM & Admin`.
* **Disabled APIs:** The GCP project must have the proper APIs enabled. See [Enable
  GCP
  APIs](https://cloud.google.com/hpc-toolkit/docs/setup/configure-environment#enable-apis).
* **Insufficient Quota:** The GCP project does not have enough quota to provision the
  requested resources. See [GCP
  Quotas](https://cloud.google.com/hpc-toolkit/docs/setup/hpc-blueprint#request-quota).
* **Required permission not found:**
  * Example: `Required 'compute.projects.get' permission for 'projects/... forbidden`
  * Credentials may not be set, or are not set correctly. Please follow instructions
    at [Cloud credentials on your
    workstation](#cloud-credentials-on-your-workstation).
  * Ensure proper permissions are set in the cloud console [IAM
    section](https://console.cloud.google.com/iam-admin/iam).


# **Samples for use cases**
| MIG Scenarios | Docker | Terraform | HPC Toolkit |
|---------------|--------|-----------|-------------|
| Simple no GPU | [terraform.tfvars](./samples/mig/simple/terraform.tfvars) | [main.tf](./samples/mig/simple/main.tf) | [blueprint](./samples/mig/simple/simple.yaml) |
| Full featured | [terraform.tfvars](./samples/mig/complex_default_network/terraform.tfvars) | [main.tf](./samples/mig/complex_default_network/main.tf) | [blueprint](./samples/mig/complex_default_network/complex_default_network.yaml) |
| Full featured with new VPC | [terraform.tfvars](./samples/mig/complex_new_network/terraform.tfvars) | [main.tf](./samples/mig/complex_new_network/main.tf) | [blueprint](./samples/mig/complex_new_network/complex_new_network.yaml) |
| Full featured with multi-NIC VPC | [terraform.tfvars](./samples/mig/complex_multi_nic_network/terraform.tfvars) | [main.tf](./samples/mig/complex_multi_nic_network/main.tf) | [blueprint](./samples/mig/complex_multi_nic_network/complex_multi_nic_network.yaml) |
| a3 VM type full featured with multi-NIC VPC | [terraform.tfvars](./samples/mig/a3_multi_nic_network/terraform.tfvars) | [main.tf](./samples/mig/a3_multi_nic_network/main.tf) | [blueprint](./samples/mig/a3_multi_nic_network/a3_multi_nic_network.yaml) |


| MIG-with-Container Scenarios | Docker | Terraform | HPC Toolkit |
|---------------|--------|-----------|-------------|
| Full featured | [terraform.tfvars](./samples/mig-with-container/simple/terraform.tfvars) | [main.tf](./samples/mig-with-container/simple/main.tf) | [blueprint](./samples/mig-with-container/simple/blueprint.yaml) |


| GKE Scenarios | Docker | Terraform | HPC Toolkit |
|---------------|--------|-----------|-------------|
| Simple with no GPU | [terraform.tfvars](./samples/gke/simple/terraform.tfvars) | [main.tf](./samples/gke/simple/main.tf) | [blueprint](./samples/gke/simple/simple.yaml) |
| Full featured with default network | [terraform.tfvars](./samples/gke/complex_gpu_default_network/terraform.tfvars) | [main.tf](./samples/gke/complex_gpu_default_network/main.tf) | [blueprint](./samples/gke/complex_gpu_default_network/complex_gpu_default_network.yaml) |
| Full featured with new network | [terraform.tfvars](./samples/gke/complex_gpu_new_network/terraform.tfvars) | [main.tf](./samples/gke/complex_gpu_new_network/main.tf) | [blueprint](./samples/gke/complex_gpu_new_network/complex_gpu_new_network.yaml) |


| GKE-beta Scenarios | Docker | Terraform | HPC Toolkit |
|--------------------|--------|-----------|-------------|
| Full featured with a3 machines and multi-NIC network | [terraform.tfvars](./samples/gke-beta/a3_multiNIC_network/terraform.tfvars) | Not Supported | Not Supported |


| Slurm Scenarios | Docker | Terraform | HPC Toolkit |
|-----------------|--------|-----------|-------------|
| Simple with no GPU | [terraform.tfvars](./samples/slurm/minimal/terraform.tfvars) | [main.tf](./samples/slurm/minimal/main.tf) | [blueprint](./samples/slurm/minimal/blueprint.yaml) |
| Full featured with multi-NIC network | [terraform.tfvars](./samples/slurm/complex_multi_nic/terraform.tfvars) | [main.tf](./samples/slurm/complex_multi_nic/main.tf) | [blueprint](./samples/slurm/complex_multi_nic/blueprint.yaml) |


# **Billing Reports**

You can view your billing reports for your HPC cluster on the [Cloud Billing
Reports](https://cloud.google.com/billing/docs/how-to/reports) page. ​​To view the
Cloud Billing reports for your Cloud Billing account, including viewing the cost
information for all of the Cloud projects that are linked to the account, you need a
role that includes the `billing.accounts.getSpendingInformation` permission on your
Cloud Billing account.

To view the Cloud Billing reports for your Cloud Billing account:

1. In the Google Cloud Console, go to `Navigation Menu` >
   [`Billing`](https://console.cloud.google.com/billing/overview).
2. At the prompt, choose the Cloud Billing account for which you'd like to view
   reports. The Billing Overview page opens for the selected billing account.
3. In the Billing navigation menu, select `Reports`.

In the right side, expand the Filters view and then filter by label, specifying the
key `aiinfra-cluster` and the desired value.

# **Known Issues**

1. ❗Error: Error waiting for Deleting Network: The network resource 'projects/xxx' is
   already being used by 'projects/firewall-yyy’.
   - This error is due to a known bug in VPC b/186792016.
2. ❗Error: Failed to get existing workspaces: querying Cloud Storage failed: Get
   "https://storage.googleapis.com/storage/v1/...": metadata: GCE metadata
   "instance/service-accounts/default/token?scopes=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fdevstorage.full_control"
   not defined
   - This error indicates that the user does not have storage object owner access in
     the project. Please get the storage object owner access or use
     `TERRAFORM_GCS_PATH=gs://<bucketname>/<foldername>` in the configuration.
3. ❗Error: Failed to get existing workspaces: querying Cloud Storage failed:
   googleapi: Error 403: username@google.com does not have serviceusage.services.use
   access to the Google Cloud project. Permission 'serviceusage.services.use' denied
   on resource (or it may not exist)., forbidden
   - This error indicates that the gcloud auth token provided as `-v
     ~/.config/gcloud:/root/.config/gcloud` or `-v
     C:\Users%username%\AppData\Roaming\gcloud:/root/.config/gcloud` has expired.
     Please renew the auth token by calling `gcloud auth application-default login`
     command or use without passing the auth token in docker run command like 
     > `docker run -it --env-file env.list
     > us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest
     > Create`
