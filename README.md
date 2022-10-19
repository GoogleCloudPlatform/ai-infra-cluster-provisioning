## TL;DR
The objective of this document is to provide a detailed design of the solution for GPU cluster provisioning to run AI/ML workloads. This solution is designed for A2+/A3 timeline. In the following sections we will compare different available options and then dive deep into the proposed solution. The instructions can be found [here](#instruction).
## CUJ
Cluster provisioning effort aims to provide a solution for the external users to provision a GPU cluster quickly and efficiently and run their AI/ML workload in minutes. Similarly it aims to provide an automated way of providing GPU clusters for the internal AI/ML pipeline.

## Detailed Design
The AI Accelerator experience team provides docker images which provision the cluster when run as a container. The docker image is self contained to create all the necessary resources for a GPU cluster. It has all the configs prepackaged and the tools installed. The configs packaged inside the image define the baseline GPU cluster. 

### Baseline cluster configuration
The baseline GPU cluster is the collection of resources recommended/supported by the AI accelerator experience team. Examples of that include Supported VM types, accelerator types, VM images, shared storage solutions like GCSFuse etc. These are first tested within the AI Accelerator experience team and then they are integrated with the cluster provisioning tool. The way they are incorporated into the tool is via Terraform configs packaged within the docker container. In some cases these features can be optional and users may choose to use it (eg: GCSFuse) but in some other cases they will be mandated by AI Accelerator exp. team (eg: DLVM image).  

### Configuration for Users
Users have control to choose values for different fields for the resources. For example Project ID, Zone, Region, Name etc. Users can also enable/disable various features using feature flags in the config, for example: GCSFuse, Multi-NIC VM etc. The configuration file contains configs as key value pairs and provided to the ‘docker run’ command. These are set as environment variables within the docker container and then entrypoint.sh script uses these environment variables to configure terraform to create resources accordingly. 
The Users can also mount a local directory in the container using ’docker run -v’ option. Then they can provide the path in the mounted volume using  ‘COPY_DIR_PATH’ and the provisioning tool will copy all the files in that location to the VM.
Optionally Users can provide a list of metadata that can be added to the VM.

#### Sample config file that the user provides.
``` 
# -----------------------------------------------------------------------------------------------
# Required environment variables.

# ACTION. This defines the intended action to perform. The supported values are: Create, Destroy
# PROJECT_ID. This is the project id to be used for creating resources. Ex: supercomputer-testing
# NAME_PREFIX. This is the name prefix to be used for naming the resources. Ex: spani
# REGION. This is the region for creating the resources. Ex: us-central1
# ZONE. This is the Zone for creating the resources. Ex: us-central1-f

# Optional Environment variables.

# INSTANCE_COUNT. This defines the VM instance count. The default value is 1 if not set.
# GPU_COUNT. This defines the GPU count per VM. The default value is 2 if not set.
# VM_TYPE. This defines the VM type. The default value is a2-highgpu-2g if not set.
# CLEANUP_ON_EXIT. This defines the cleanup behaviour when the container exits. If set to 'yes' then the cluster is cleaned up when container exits. The supported values are: yes, no.
# GCS_PATH. Google cloud storage bucket path to use for state management and copying scripts. Ex: gs://spani-tst
# COPY_DIR_PATH. Local directory can be mounted to the docker container and path can be specified via COPY_DIR_PATH environment variable to copy files to the VM.
# METADATA. This defines optional metadata to be set for the VM. Ex: { key1 = "val", key2 = "val2"}
# -----------------------------------------------------------------------------------------------

ACTION=Destroy
PROJECT_ID=supercomputer-testing
NAME_PREFIX=spani
REGION=us-central1
ZONE=us-central1-f
GCS_PATH=gs://spani-tst
COPY_DIR_PATH=/usr/cp
METADATA={ key1 = "val", key2 = "val2"}
```

### Setting up Terraform to create resources
The user updates the config file and runs the docker image with the config file to create resources. All the setup needed before calling terraform to create resources is handled by entrypoint.sh script. This is packaged in the docker image and gets executed when the container starts. The entrypoint script validates environment variables and errors out if required ones are not provided. After that it uses the environment variables values to create the ‘tf.auto.tfvar’ file which is used by terraform to create the resources.

### State management across sessions
When terraform is executed to create the resources, it creates state files to keep track of the created resources. While changing or destroying resources, terraform uses these statefiles. If these state files are created within the container, then they will be lost when the container exits. Thai will result in leaking of the resources. Having the state files in the container forces cleanup resources before the container exits. This ties the cluster lifespan to that of the container. So to have better control over the resources we need to have the state files managed in cloud storage. That way multiple runs of the container can use the same state files to manage the resources. 
Using the provisioning tool the user can provide a GCS bucket path that the entrypoint.sh script uses for managing the terraform state and sets it as the backend for terraform. If the user does not provide a GCS bucket path then the provisioning tool creates a GCS bucket for managing terraform state, but for this the user needs to have permission to create a GCS bucket in the project they are using.

### Resource cleanup
Since the resource state is stored outside of the container, the GPU cluster lifespan is decoupled from the container’s lifespan. Now the user can run the container and provide ‘ACTION=Create’ in the config file to create the resources. They can run the container again and provide ‘ACTION=Destroy’ to destroy the container. The terraform state stored in the GCS bucket is cleared when the destroy operation is called.
Users can alternatively set ‘CLEANUP_ON_EXIT=yes’ which triggers the resource cleanup when the container exits. In this case state management happens within the container and the state files are not stored in the GCS bucket.

## Instruction
1. gcloud auth login.
2. ***[OPTIONAL - if project not set already]*** gcloud config set account supercomputer-testing
3. Create env.list file. The sample env.list can be found [here](#sample-config-file-that-the-user-provides). 
4. ***[SIMPLE]*** docker run -it --env-file env.list us-central1-docker.pkg.dev/supercomputer-testing/cluster-provision-repo-2/cluster-provision-image:lkg
5. ***[OPTIONAL - GCS bucket not provided]*** Need storage object owner access if you don't already have a storage bucket to reuse.
6. ***[OPTIONAL - Pull docker image before hand]***
docker pull us-central1-docker.pkg.dev/supercomputer-testing/cluster-provision-repo-2/cluster-provision-image:lkg
7. ***[OPTIONAL - Mount local directory]***
docker run -v /home/soumyapani/sp-tmp:/usr/cp -it --env-file env.list us-central1-docker.pkg.dev/supercomputer-testing/cluster-provision-repo-2/cluster-provision-image:lkg

## Known Issues
1. Error: Error waiting for Deleting Network: The network resource 'projects/xxx' is already being used by 'projects/firewall-yyy’
This is due to a known bug in VPC b/186792016.
