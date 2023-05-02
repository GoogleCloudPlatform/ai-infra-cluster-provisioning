# Overview

The Cluster provisioning tool aims to provide a solution for the external users to
provision a GPU cluster quickly and efficiently and run their AI/ML workload in
minutes. Similarly it aims to provide an automated way of providing GPU clusters for
the internal AI/ML pipeline. The cluster provisioning tool is a docker images which
provision the cluster when run as a container. The docker image is self contained to
create all the necessary resources for a GPU cluster. It has all the configs
prepackaged and the tools installed. The configs packaged inside the image define the
baseline GPU cluster. 

### Baseline cluster configuration

The baseline GPU cluster is the collection of resources recommended/supported by the
AI accelerator experience team. Examples of that include Supported VM types,
accelerator types, VM images, shared storage solutions like GCSFuse etc. These are
first tested within the AI Accelerator experience team and then they are integrated
with the cluster provisioning tool. The way they are incorporated into the tool is
via Terraform configs packaged within the docker container. In some cases these
features can be optional and users may choose to use it (eg: GCSFuse) but in some
other cases they will be mandated by AI Accelerator exp. team (eg: DLVM image).  

The default GPU cluster that gets created by the cluster provisioning tool is a
single instance VM of type “a2-highgpu-2g” with 2 “Nvidia-tesla-a100” GPUs attached
to it. It uses pytorch-1-12-gpu-debian-10 image. There is no startup script or any
orchestrator (like Ray) set up. The jupyter notebook endpoint is accessible for this
VM instance. There is a GCS bucket created in the project provided by the user to
manage the terraform state.  Users can create more advanced clusters using
configuration described below.  

### Configuration for Users

Users have control to choose values for different fields for the resources. The
mandatory parameters are:
1. **PROJECT_ID**: The project ID to use for resource creation. 
2. **NAME_PREFIX**: The name prefix to use for creating the resources. This is the
   unique ID for the clusters created using the provisioning tool. 
3. **ZONE**: The zone to use for resource creation.

The optional parameters are:
1. ***INSTANCE_COUNT***. This defines the VM instance count. The default value is 1
   if not set.
1. ***GPU_COUNT***. This defines the GPU count per VM. The default value is 2 if not
   set.
1. ***VM_TYPE***. This defines the VM type. The default value is a2-highgpu-2g if not
   set.
1. ***ACCELERATOR_TYPE***. This defines the Accelerator type. The default value is
   nvidia-tesla-a100 if not set.
1. ***IMAGE_FAMILY_NAME***. This defines the image family name for the VM. The
   default value is pytorch-1-12-gpu-debian-10 if not set.
1. ***IMAGE_NAME***. This defines the image name for the VM. The default value is
   c2-deeplearning-pytorch-1-12-cu113-v20221107-debian-10 if not set.
1. ***IMAGE_PROJECT***. This defines the image project name for the VM. The default
   value is ml-images project.
1. ***DISK_SIZE_GB***. This defines the disk size in GB for the VMs. The default
   value is 2000 GB(2 TB) if not specified.
1. ***DISK_TYPE***. This defines the disk type to use for VM creation. The default
   value is pd-ssd if not defined.
1. ***TERRAFORM_GCS_PATH***. Google cloud storage bucket path to use for state
   management and copying scripts. If not provided then a default GCS bucket is
   created in the project. The name of the bucket is
   ‘aiinfra-terraform-<PROJECT_ID>’. For each deployment a separate folder is created
   under this GCS bucket in the name ‘<NAME_PREFIX-deployment>’. Ex:
   gs://test-bucket/deployment
1. ***VM_LOCALFILE_DEST_PATH***. This defines the destination directory path in the
   VM for file copy. If any local directory is mounted at "/usr/aiinfra/copy" in the
   docker container then all the files in that directory are copied to the
   VM_LOCALFILE_DEST_PATH in the VM. If not specified the default value is
   '/usr/aiinfra/copy'.
1. ***METADATA***. This defines optional metadata to be set for the VM. Ex: { key1 =
   "val", key2 = "val2"}
1. ***LABELS***. This defines key value pairs to set as labels when the VMs are
   created. Ex: { key1 = "val", key2 = "val2"} 
1. ***STARTUP_COMMAND***. This defines the startup command to run when the VM starts
   up. Ex: python /usr/cp/train.py
1. ***ORCHESTRATOR_TYPE***. This defines the Orchestrator type to be set up on the
   VMs. The currently supported orchestrator types are 
    -  __none__ (default): No cluster orchestration. A Single MIG will be created.
    -  __ray__: A Ray cluster is created using the MIG instances.
    -  __gke__: A private GKE cluster is created with private node pool following the
       recommendations from the GKE team.
    -  __slurm__: Login and controller nodes are created along with static compute
       nodes for a Slurm cluster.
1. ***SLURM_NODE_COUNT_STATIC***: The number of nodes statically allocated for Slurm
   cluster.
1. ***SLURM_NODE_COUNT_DYNAMIC_MAX***: The maximum number of nodes allowed to be
   dynamically allocated for Slurm cluster.
1. ***GKE_NODE_POOL_COUNT***: The number of homogeneous node pools for GKE cluster.
   Only applicable when `ORCHESTRATOR_TYPE` is `gke`.
1. ***GKE_NODE_COUNT_PER_NODE_POOL***: The desired node count per node pool for GKE
   cluster. Only applicable when `ORCHESTRATOR_TYPE` is `gke`.
1. ***GKE_ENABLE_COMPACT_PLACEMENT***: The flag to enable compact placement policy
   for GKE node pools. The default value is `true`.
1. ***GKE_VERSION***: The GKE version to use for creating the GKE cluster. Default
   value is the latest GKE version for the project in the region. Only applicable
   when `ORCHESTRATOR_TYPE` is `gke`. Ex: `GKE_VERSION=1.25.7-gke.1000`
1. ***CUSTOM_NODE_POOL***: The custom node pool description for GKE. The structure of
   the custom node pool is list of node pool objects. The node pool object is 
    ```tf
    name                     = string
    zone                     = string
    node_count               = number
    machine_type             = string
    guest_accelerator_count  = number
    guest_accelerator_type   = string
    enable_compact_placement = bool
    ```
    
    Example:
    `CUSTOM_NODE_POOL=[{"name"="sp-test-pool-1","zone"="us-central1-a","node_count"=2,"machine_type"="a2-highgpu-2g","guest_accelerator_count"=2,"guest_accelerator_type"="nvidia-tesla-a100","enable_compact_placement"=true},{"name"="sp-test-pool-2","zone"="us-central1-a","node_count"=2,"machine_type"="a2-highgpu-2g","guest_accelerator_count"=2,"guest_accelerator_type"="nvidia-tesla-a100","enable_compact_placement"=true}]`
1. ***KUBERNETES_SETUP_CONFIG***: The configuration to perform various kubernetes setup
   on the GKE cluster created by the tool. This includes KSA binding. The structure of 
   the `KUBERNETES_SETUP_CONFIG` object is
   ```tf
    enable_k8s_setup                     = bool
    kubernetes_service_account_name      = string
    kubernetes_service_account_namespace = string
    node_service_account                 = string
   ```
   * `enable_k8s_setup`: This is the flag to enable kubernetes setup. The default value is
         true if the `ORCHESTRATOR_TYPE` is `gke`.
   * `kubernetes_service_account_name`: The kubernetes service account (KSA) name. The
         value is `aiinfra-gke-sa`.
   * `kubernetes_service_account_namespace`: The kubernetes service account (KSA) namespace.
         The default value is `default`.
   * `node_service_account`: The google service account (GSA) name to bind to the KSA. The 
         default value is project service account email.
   
   Example: 
   `KUBERNETES_SETUP_CONFIG={"enable_k8s_setup"=true,"kubernetes_service_account_name"="test-sa","kubernetes_service_account_namespace"="default","node_service_account"="xxxxxx-compute@developer.gserviceaccount.com"}`

1. ***GCS_MOUNT_LIST***. This defines the list of GCS buckets to mount. The format is
   `<bucket1>:</mount/path1>,<bucket2>:</mount/path2>`. For example:
   GCS_MOUNT_LIST=test-gcs-bucket-name:/usr/trainfiles
1. ***NFS_FILESTORE_LIST***. This defines the list of NFS file shares to mount. The
   format is `</mount/path1>:<NFS filestore type>,</mount/path2>:<NFS filestore
   type>:<NFS filestore size in GB>`. For example:
   NFS_FILESTORE_LIST=/usr/nfsshare1:BASIC_SSD
    -  The `<NFS filestore type>` cannot be empty. The supported values are
       `BASIC_HDD`,`BASIC_SSD`,`HIGH_SCALE_SSD` and `ENTERPRISE`.
    -  The `<NFS filestore size in GB>` can be empty and the default value is 2560 GB
       (2.5 TB).
1. ***SHOW_PROXY_URL***. This controls if the Jupyter notebook proxy url is retrieved
   for the cluster or not. The default value is yes. If this is present and set to
   no, then connection information is not collected. The supported values are: yes,
   no.
1. ***MINIMIZE_TERRAFORM_LOGGING***. This controls the verbosity of terraform logs.
   When any value is set for this parameter, the terraform output is redirected to a
   local file and not printed on syserr. The log file is then uploaded to storage
   account. Any value can be set for this parameter, e.g.: yes, true.
1. ***NETWORK_CONFIG***. This controls the VPC type to be used for the MIG. The
   supported values are default_network, new_network and multi_nic_network. The
   default value is default_network. The behavior is 
    -  __default_network__: MIG uses the default VPC in the project.
    -  __new_network__: A new VPC is created for the MIG.
    -  __multi_nic_network__: New VPCs are created and used by all the VMs in the
       MIG. By default 5 new VPCs are created and 5 NICs are used for the MIG but
       that value is configurable.
1. ***ENABLE_OPS_AGENT***. Can be one of:
    - `true` (default): Install Ops Agent with random-backoff retries
    - `false`: Do not install Ops Agent
1. ***ENABLE_NOTEBOOK***. Can be one of:
    - `true` (default): Sets up jupyter notebook for the vm instances.
    - `false`: Do not set up jupyter notebook.

The user needs to provide value for the above mandatory parameters. All other
parameters are optional and default behavior is described above. Users can also
enable/disable various features using feature flags in the config, for example:
ORCHESTRATOR_TYPE, SHOW_PROXY_URL, GCSFuse, Multi-NIC VM etc. The configuration file
contains configs as key value pairs and provided to the ‘docker run’ command. These
are set as environment variables within the docker container and then entrypoint.sh
script uses these environment variables to configure terraform to create resources
accordingly. 

#### [Sample config file that the user provides](examples/env_files/env.list)

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
## Usage via Docker image

The user updates the config file and runs the docker image with the config file to
create resources using the ‘docker run’ command. As part of the run command, users
have to specify an action. The action can be Create, Destroy, Validate or Debug. The
sample command looks like
```
docker run -it --env-file env.list us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest Create

docker run -it --env-file env.list us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest Destroy
```
All the setup needed before calling terraform to create resources is handled by
entrypoint.sh script. This is packaged in the docker image and gets executed when the
container starts. The entrypoint script validates environment variables and errors
out if required ones are not provided. After that it uses the environment variables
values to create the ‘tf.auto.tfvar’ file which is used by terraform to create the
resources.

### User Authentication

The cluster provisioning tool interacts with GCP to create cloud resources on behalf
of the user. So for doing that it needs the user’s authentication token with GCP.
There are 3 environments where we expect the cluster provisioning tool to run. They
are

1. Cloud shell: In the cloud shell environment, the default cloud authentication
   token is available that cluster provisioning tool uses for resource creation. No
   additional action is needed from the user. 
2. User machine with gcloud authentication: In the case where the user is running the
   cluster provisioning tool on their machine, they need to be authenticated with GCP
   for resource creation. There are 2 ways to do this.
   - Running ‘gcloud auth application-default login’ and mounting the local gcloud
     config to the container. For that use the  `docker run` command with option `-v
     ~/.config/gcloud:/root/.config/gcloud` for Linux or option `-v
     C:\Users%username%\AppData\Roaming\gcloud:/root/.config/gcloud` for windows.
   - Simply run the container image using ‘docker run’. When the cluster provisioning
     tool does not find any default authentication token it asks for manual
     authentication. Follow the prompt and provide the authorization code. The
     authorization prompt looks like below which is the same as gcloud authorization
     prompt.
    ```
    ================SETTING UP ENVIRONMENT FOR TERRAFORM================
    Setting Action to destroy
    Found Project ID test-project
    ERROR: (gcloud.projects.describe) You do not currently have an active account selected.
    Please run:
    
      $ gcloud auth login
    
    to obtain new credentials.
    
    If you have already logged in with a different account:
    
        $ gcloud config set account ACCOUNT
    
    to select an already authenticated account to use.
    Failed to get project number. Return value = 1
    No authenticated account found.
    Go to the following link in your browser:
    
        https://accounts.google.com/o/oauth2/auth?...........
    
    Enter authorization code: 4/0Afxxxxxxxxxxxx
    ```
3. LLM pipeline: LLM pipeline uses VMs to run the cluster provisioning tool and the
   VM has default cloud authentication token available. So additional authentication
   is not needed here.


### State management across sessions

When terraform is executed to create the resources, it creates state files to keep
track of the created resources. While changing or destroying resources, terraform
uses these state files. If these state files are created within the container, then
they will be lost when the container exits. That will result in leaking of the
resources. Having the state files in the container forces cleanup resources before
the container exits. This ties the cluster lifespan to that of the container. So to
have better control over the resources we need to have the state files managed in
cloud storage. That way multiple runs of the container can use the same state files
to manage the resources. Using the provisioning tool the user can provide a GCS
bucket path that the entrypoint.sh script uses for managing the terraform state and
sets it as the backend for terraform. If the user does not provide a GCS bucket path
then the provisioning tool creates a GCS bucket for managing terraform state, but for
this the user needs to have permission to create a GCS bucket in the project they are
using.

### Copying AI/ML training script to the GPU cluster

There are 2 supported ways to copy training scripts to the GPU cluster. 
1. The first and preferred method is via GCSFuse. Users can simply provide their GCS
   bucket where they can store training scripts and data via the ‘GCS_MOUNT_LIST’
   parameter. Cluster provisioning tool will mount the GCS bucket in the VM as a
   local volume using GCSFuse.
2. The second way is via copying scripts from the local directory. For that
   - First the user needs to mount a local directory containing training scripts to
     `"/usr/aiinfra/copy"` location. To do that use the ‘docker run’ command with
     option ‘-v /localdirpath:/usr/aiinfra/copy ’
   - Then the user needs to provide the destination location as
     `VM_LOCALFILE_DEST_PATH` parameter. All the files under the mounted local
     directory will be copied to all the VMs under the path provided. If
     `VM_LOCALFILE_DEST_PATH`  is not provided then the default destination path is
     `"/usr/aiinfra/copy"` in the VM.

### Multi-node training

For multi-node training, we need to set up an orchestrator on all the VMs of the GPU
cluster. Users can choose the orchestrator via ‘ORCHESTRATOR_TYPE’ parameter.
Currently we support only Ray as our orchestrator. We will be adding support for more
orchestrator types like Slurm shortly.

### Shared Filesystem

For sharing data across machines running AI workload, users can use a shared file
system. Currently we are using NFS filestore or GCS bucket as shared file system
across machines. Users can use the `GCS_MOUNT_LIST` parameter to provide a comma
separated list of GCS buckets and their mount paths. Similarly they can use
`NFS_FILESTORE_LIST` parameter to provide comma separated list of paths. For each
filestore path, a new filestore will be created and mounted to the path specified on
every VM in the cluster.

### Connecting to the GPU cluster and running the training script

Jupyter notebook is the default and recommended way to connect to the GPU cluster.
All the VMs that get created through the cluster provisioning tool have proxy enabled
for jupyter notebook. As part of the DLVM image, jupyter notebook server is started
when the VM is created and a proxy url is created to access the notebook endpoint.
After successfully creating the VMs, the cluster provisioning tool waits for the
jupyter notebook server to be up and provides the url to connect, which looks like
below. 
```
Apply complete! Resources: 7 added, 0 changed, 0 destroyed.
Terraform apply finished successfully.
Jupyter notebook endpoint not available yet. Sleeping 15 seconds.
Jupyter notebook endpoint not available yet. Sleeping 15 seconds.
 Terraform state file location: 
gs://test-bucket/test-dir/terraform/state
 Use below links to connect to the VMs: 
test-vm-gh9l:https://1896669fce99a2c1-dot-us-central1.notebooks.googleusercontent.com
test-vm-nrcv:https://11a0dd452fdf76d3-dot-us-central1.notebooks.googleusercontent.com
```
The user can use this URL on their browser to connect to the jupyter notebook and
execute their training script. There are some default training scripts provided in
the VMs under location `/home/jupyter/aiinfra-sample`. Users can run those scripts
after connecting to the VM to see them in action. The example scripts use `Ray` for
multi node trainings. So please use `ORCHESTRATOR_TYPE=Ray` while creating the
cluster to run the script for multi-node training.
![image](files/../docs/images/example_script.png)

### Resource cleanup

Since the resource state is stored outside of the container, the GPU cluster lifespan
is decoupled from the container’s lifespan. Now the user can run the container and
provide ‘Create’ as part of the ‘docker run’ command to create the resources. They
can run the container again and provide ‘Destroy’ to destroy the container. The
terraform state stored in the GCS bucket is cleared when the destroy operation is
called.

### Instructions

1. gcloud auth application-default login.
1. ***[`OPTIONAL - if project not set already`]*** gcloud config set account
   supercomputer-testing
1. Create env.list file. The sample env.list can be found
   [here](#sample-config-file-that-the-user-provides). 
1. ***[`SIMPLE CREATE`]*** 
   > docker run -it --env-file env.list
   > us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest
   > Create
1. ***[`SIMPLE DESTROY`]*** 
   > docker run -it --env-file env.list
   > us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest
   > Destroy
1. ***[`OPTIONAL - Pull docker image before hand`]*** 
   > docker pull
   > us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest
1. ***[`OPTIONAL - Mount local directory`]*** 
   > docker run -v /usr/username/test:/usr/aiinfra/copy -it --env-file env.list
   > us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest
   > Create
1.  ***[`OPTIONAL - Mount gcloud config for auth token`]*** 
    > `Linux` docker run -v ~/.config/gcloud:/root/.config/gcloud -it --env-file
    > env.list
    > us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest
    > Create
    
    > `Windows` docker run -v
    > C:\Users%username%\AppData\Roaming\gcloud:/root/.config/gcloud -it --env-file
    > env.list
    > us-docker.pkg.dev/gce-ai-infra/cluster-provision-dev/cluster-provision-image:latest
    > Create
1. ***[`OPTIONAL - GCS bucket not provided`]*** 
    > Need storage object owner access if you don't already have a storage bucket to
    > reuse.

## Usage via Terraform
The user can use the [aiinfra-cluster module from the cluster provisioning tool
GitHub
repository](https://github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning/tree/main/aiinfra-cluster).
It can be done by simply providing the source like below.
```tf
module "aiinfra-cluster" {
  source             = "github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning//aiinfra-cluster"
}
```

An example terraform config using the aiinfra-cluster module can be found
1. [MIG GPU cluster](examples/terraform-config/gpu-mig-cluster/)
2. [GKE GPU cluster](examples/terraform-config/gpu-gke-cluster/)

### Installing terraform dependencies
1. [Install Google Cloud CLI](https://cloud.google.com/sdk/docs/install)
1. [Download Terraform version 1.3.7 or
   later](https://developer.hashicorp.com/terraform/downloads)

### Supplying cloud credentials to Terraform

Terraform can discover credentials for authenticating to Google Cloud Platform in
several ways. We will summarize Terraform's documentation for using
[gcloud](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/getting_started#configuring-the-provider)
from your workstation and for automatically finding credentials in cloud
environments.

#### Cloud credentials on your workstation

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

### Terraform Deployment Troubleshooting

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


## Usage via HPCToolkit
The cluster provisioning tool exposes the functionalities to provisioning a GPU
cluster via Terraform modules. So the GPU cluster provisioning functionalities can be
directly integrated with HPC toolkit.

This directory contains HPC toolkit blueprints that uses aiinfra-cluster module to
create GPU clusters.

Below is a short introduction to [HPC
toolkit](https://cloud.google.com/hpc-toolkit/docs/overview) and the resource
materials for it.

### HPC Toolkit

[HPC toolkit](https://cloud.google.com/hpc-toolkit/docs/overview) is an open-source
software offered by Google Cloud which makes it easy for customers to deploy HPC
environments on Google Cloud.

HPC Toolkit allows customers to deploy turnkey HPC environments (compute, networking,
storage, etc.) following Google Cloud best-practices, in a repeatable manner. The HPC
Toolkit is designed to be highly customizable and extensible, and intends to address
the HPC deployment needs of a broad range of customers.

The HPC Toolkit Repo is open-source and available
[here](https://github.com/GoogleCloudPlatform/hpc-toolkit)

### Resources

1. [HPC Toolkit Repo](https://github.com/GoogleCloudPlatform/hpc-toolkit)
2. [HPC Toolkit
   Quickstart](https://github.com/GoogleCloudPlatform/hpc-toolkit#quickstart)
3. [HPC Toolkit
   dependencies](https://cloud.google.com/hpc-toolkit/docs/setup/install-dependencies)
4. [Installing Terraform](https://developer.hashicorp.com/terraform/downloads)
5. [Installing Packer](https://developer.hashicorp.com/packer/downloads)
6. [Installing Go](https://go.dev/doc/install)
7. [HPC toolkit
   Troubleshooting](https://github.com/GoogleCloudPlatform/hpc-toolkit#troubleshooting)

### HPC toolkit Blueprints in this repo
#### [aiinfra-GPU-cluster](examples/hpc-toolkit-blueprint/aiinfra-gpu-cluster.yaml)
#### [aiinfra-GKE-cluster](examples/hpc-toolkit-blueprint/aiinfra-gke-cluster.yaml)


## Billing Reports

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

## Known Issues

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
