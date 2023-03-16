#!/bin/bash

# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#
# method to set environment variables for terraform apply.
#
_set_terraform_env_var() {
    # remove tf.auto.tfvars file if exist.
    rm -f /usr/primary/tf.auto.tfvars

    # Check cluster provisioning action.
    if [[ -z "$ACTION" ]]; then
        echo -e "${RED} Cluster provisioning action is not defined. Please provide 'Create' or 'Destroy' in the 'docker run' command. Exiting.. ${NOC}"
        exit 1
    fi

    # setting Project ID and service account information.
    if [[ -z "$PROJECT_ID" ]]; then
        echo "PROJECT_ID environment variable not found. Exiting.."
        exit 1
    else
        echo "Found Project ID $PROJECT_ID"
        echo "project_id = \"$PROJECT_ID\"" > /usr/primary/tf.auto.tfvars
        proj_ret=0
        project_num=`gcloud projects describe $PROJECT_ID --format="value(projectNumber)"` || proj_ret=$?
        if [ $proj_ret != 0 ]; then
            echo "Failed to get project number. Return value = $proj_ret"
            auth_ret=0
            auth_res=`gcloud auth list --format="value(ACCOUNT)"` || auth_ret=$?
            if [ $auth_ret != 0 ]; then
                echo "Failed to list auth accounts. Return = $auth_ret."
                gcloud auth list
                exit $auth_ret
            elif [ -z "$auth_res" ]; then
                echo "No authenticated account found."
                gcloud auth login --update-adc
                val=`gcloud config set project $PROJECT_ID` 
                auth_res=`gcloud auth list --format="value(ACCOUNT)"` || auth_ret=$?
                echo "Logged in as $auth_res"
            fi
            project_num=`gcloud projects describe $PROJECT_ID --format="value(projectNumber)"`
        fi
        echo "Project number is $project_num"
        project_email=$project_num-compute@developer.gserviceaccount.com
        echo "Exporting service account as $project_email"
        cat >>/usr/primary/tf.auto.tfvars <<EOF
service_account = {
  email = "${project_email}"
  scopes = [
    "https://www.googleapis.com/auth/devstorage.read_write",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
    "https://www.googleapis.com/auth/servicecontrol",
    "https://www.googleapis.com/auth/service.management.readonly",
    "https://www.googleapis.com/auth/trace.append"
  ]
}
EOF
        val=`gcloud config set project $PROJECT_ID`
    fi

    # setting name prefix and deployment name information.
    if [[ -z "$NAME_PREFIX" ]]; then
        echo "NAME_PREFIX environment variable not found. Exiting.."
        exit 1
    else
        depl_name=$NAME_PREFIX-dpl
        echo "Found Name prefix $NAME_PREFIX"
        echo "name_prefix = \"$NAME_PREFIX\"" >> /usr/primary/tf.auto.tfvars
        echo "deployment_name = \"$depl_name\"" >> /usr/primary/tf.auto.tfvars
    fi

    # setting zone and region information
    if [[ -z "$ZONE" ]]; then
        echo "ZONE environment variable not found. Exiting.."
        exit 1
    else
        shopt -s extglob
        export REGION=${ZONE/%-+([a-z0-9])/}
        echo "Setting region to $REGION and zone to $ZONE."
        echo "zone = \"$ZONE\"" >> /usr/primary/tf.auto.tfvars
        echo "region = \"$REGION\"" >> /usr/primary/tf.auto.tfvars
    fi

    # setting instance count
    if [[ -z "$INSTANCE_COUNT" ]]; then
        echo "INSTANCE_COUNT environment variable not found. Default value is 0."
        export INSTANCE_COUNT=0
    else
        echo "Setting instance count to $INSTANCE_COUNT"
    fi
    echo "instance_count = $INSTANCE_COUNT" >> /usr/primary/tf.auto.tfvars

    # setting gpu count
    if [[ -z "$GPU_COUNT" ]]; then
        echo "GPU_COUNT environment variable not found. Default value is 2"
        export GPU_COUNT=2
    else
        echo "Setting gpu count to $GPU_COUNT"
    fi
    echo "gpu_per_vm = $GPU_COUNT" >> /usr/primary/tf.auto.tfvars

    # setting vm type
    if [[ -z "$VM_TYPE" ]]; then
        echo "VM_TYPE environment variable not found. Default value is a2-highgpu-2g."
        export VM_TYPE=a2-highgpu-2g
    else
        echo "Setting vm type to $VM_TYPE"
    fi
    echo "machine_type = \"$VM_TYPE\"" >> /usr/primary/tf.auto.tfvars

    # setting metadata info
    if [[ -z "$METADATA" ]]; then
        echo "metadata = {}" >> /usr/primary/tf.auto.tfvars
    else
        echo "Setting metadata value to $METADATA"
        echo "metadata = $METADATA" >> /usr/primary/tf.auto.tfvars
    fi

    # setting accelerator type
    if [[ -z "$ACCELERATOR_TYPE" ]]; then
        echo "ACCELERATOR_TYPE environment variable not found. Default value is nvidia-tesla-a100."
        export ACCELERATOR_TYPE=nvidia-tesla-a100
    else
        echo "Setting accelerator type to $ACCELERATOR_TYPE"
    fi
    echo "accelerator_type = \"$ACCELERATOR_TYPE\"" >> /usr/primary/tf.auto.tfvars

    # setting image name
    if [[ ! -z "$IMAGE_FAMILY_NAME" ]] && [[ ! -z "$IMAGE_NAME" ]]; then
        echo -e "${RED} Please provide either IMAGE_NAME or IMAGE_FAMILY_NAME. Exiting.. ${NOC}"
        exit 1
    fi

    if [[ -z "$IMAGE_FAMILY_NAME" ]]; then
        if [[ -z "$IMAGE_NAME" ]]; then
            echo "IMAGE_NAME environment variable not found. Default image family pytorch-1-12-gpu-debian-10 will be used."
            export IMAGE_FAMILY_NAME=pytorch-1-12-gpu-debian-10
            echo "instance_image = {" >> /usr/primary/tf.auto.tfvars
            echo "  family  = \"$IMAGE_FAMILY_NAME\"" >> /usr/primary/tf.auto.tfvars
            echo "  name  = \"\"" >> /usr/primary/tf.auto.tfvars
            echo "  project = \"ml-images\"" >> /usr/primary/tf.auto.tfvars
            echo "}" >> /usr/primary/tf.auto.tfvars
        else
            echo "Setting image name value to $IMAGE_NAME"
            echo "instance_image = {" >> /usr/primary/tf.auto.tfvars
            echo "  family  = \"\"" >> /usr/primary/tf.auto.tfvars
            echo "  name  = \"$IMAGE_NAME\"" >> /usr/primary/tf.auto.tfvars
            echo "  project = \"ml-images\"" >> /usr/primary/tf.auto.tfvars
            echo "}" >> /usr/primary/tf.auto.tfvars
        fi
    else
        echo "Setting image family name value to $IMAGE_FAMILY_NAME"
        echo "instance_image = {" >> /usr/primary/tf.auto.tfvars
        echo "  family  = \"$IMAGE_FAMILY_NAME\"" >> /usr/primary/tf.auto.tfvars
        echo "  name  = \"\"" >> /usr/primary/tf.auto.tfvars
        echo "  project = \"ml-images\"" >> /usr/primary/tf.auto.tfvars
        echo "}" >> /usr/primary/tf.auto.tfvars
    fi

    # setting labels
    uuidvar=`dbus-uuidgen`
    clusternum=${uuidvar:0:6}
    if [[ -z "$LABELS" ]]; then
        echo "labels = { aiinfra-cluster=\"$clusternum\" }" >> /usr/primary/tf.auto.tfvars
    else
        echo "Setting labels value to $LABELS"
        finalLabel=${LABELS/"}"/", aiinfra-cluster=\"$clusternum\" }"}
        echo "labels = $finalLabel" >> /usr/primary/tf.auto.tfvars
    fi
    
    # setting disk information
    if [[ -z "$DISK_SIZE_GB" ]]; then
        export DISK_SIZE_GB=2000 
    fi
    if [[ -z "$DISK_TYPE" ]]; then
        export DISK_TYPE=pd-ssd
    fi
    echo "Setting disk size to $DISK_SIZE_GB GB."
    echo "disk_size_gb = $DISK_SIZE_GB" >> /usr/primary/tf.auto.tfvars
    echo "Setting disk type to $DISK_TYPE."
    echo "disk_type = \"$DISK_TYPE\"" >> /usr/primary/tf.auto.tfvars

    # setting network configuration
    if [[ -z "$NETWORK_CONFIG" ]]; then
        echo "Using default VPC."
        echo "network_config = \"default_network\"" >> /usr/primary/tf.auto.tfvars
    else
        trimmednetConfig=${NETWORK_CONFIG##*( )}
        trimmednetConfig=${trimmednetConfig%%*( )}
        case "${trimmednetConfig,,}" in
           "default_network") 
               echo "Network configuration is $NETWORK_CONFIG. Using default VPC."
               echo "network_config = \"${trimmednetConfig,,}\"" >> /usr/primary/tf.auto.tfvars
               ;;
            "new_network") 
               echo "Network configuration is $NETWORK_CONFIG. Creating new private VPC."
               echo "network_config = \"${trimmednetConfig,,}\"" >> /usr/primary/tf.auto.tfvars
               ;;
            "multi_nic_network") 
               echo "Network configuration is $NETWORK_CONFIG. Creating multi-nic VPC."
               echo "network_config = \"${trimmednetConfig,,}\"" >> /usr/primary/tf.auto.tfvars
               ;;
           *)
               echo -e "${RED} Network config $NETWORK_CONFIG not supported. Supported values are \"new_network\" or \"multi_nic_network\". Exiting.. ${NOC}"
               exit 1
               ;;
        esac
    fi

    # setting GCS mount list
    if [[ -n "$GCS_MOUNT_LIST" ]]; then
        echo "gcs_mount_list = \"$GCS_MOUNT_LIST\"" >> /usr/primary/tf.auto.tfvars
    fi
    
    # setting MFS filestore list
    if [[ -n "$NFS_FILESHARE_LIST" ]]; then
        echo "nfs_filestore_list = \"$NFS_FILESHARE_LIST\"" >> /usr/primary/tf.auto.tfvars
    fi

    # setting orchestrator type
    if [[ -n "$ORCHESTRATOR_TYPE" ]]; then
        echo "orchestrator_type = \"${ORCHESTRATOR_TYPE,,}\"" >> /usr/primary/tf.auto.tfvars
    fi

    # setting startup command
    if [[ -n "$STARTUP_COMMAND" ]]; then
        echo "startup_command = \"$STARTUP_COMMAND\"" >> /usr/primary/tf.auto.tfvars
    fi

    # setting enable ops agent
    if [[ -n "$ENABLE_OPS_AGENT" ]]; then
      echo "enable_ops_agent = \"${ENABLE_OPS_AGENT,,}\"" >> /usr/primary/tf.auto.tfvars
    fi

    # setting disable ops agent
    if [[ -n "$ENABLE_NOTEBOOK" ]]; then
      echo "enable_notebook = \"${ENABLE_NOTEBOOK,,}\"" >> /usr/primary/tf.auto.tfvars
    fi
}

_set_node_pools_for_gke() {
    if [[ -n "$GKE_NODE_POOL_COUNT" ]]; then
        echo "gke_node_pool_count = $GKE_NODE_POOL_COUNT" >> /usr/primary/tf.auto.tfvars
    fi

    if [[ -n "$GKE_NODE_COUNT_PER_NODE_POOL" ]]; then
        echo "gke_node_count_per_node_pool = $GKE_NODE_COUNT_PER_NODE_POOL" >> /usr/primary/tf.auto.tfvars
    fi

    if [[ -n "$CUSTOM_NODE_POOL" ]]; then
        echo "custom_node_pools = $CUSTOM_NODE_POOL" >> /usr/primary/tf.auto.tfvars
    fi
}
