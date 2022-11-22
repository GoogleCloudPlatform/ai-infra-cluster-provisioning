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
# test pr submit
# method to set environment variables for terraform apply.
#
_set_terraform_env_var() {
    # remove tf.auto.tfvars file if exist.
    rm -f /usr/primary/tf.auto.tfvars

    # Check cluster provisioning action.
    if [[ -z "$ACTION" ]]; then
        echo "Cluster provisioning action is not defined. Example: 'Create' or 'Destroy'. Exiting.."
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
                gcloud auth login
                gcloud auth application-default login
                val=`gcloud config set project $PROJECT_ID` 
                auth_res=`gcloud auth list --format="value(ACCOUNT)"` || auth_ret=$?
                echo "Logged in as $auth_res"
            fi
            project_num=`gcloud projects describe $PROJECT_ID --format="value(projectNumber)"`
        fi
        echo "Project number is $project_num"
        project_email=$project_num-compute@developer.gserviceaccount.com
        echo "Exporting service account as $project_email"
        echo "service_account = \"$project_email\"" >> /usr/primary/tf.auto.tfvars
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
    if [[ -z "$REGION" ]]; then
        echo "REGION environment variable not found. Exiting.."
        exit 1
    elif [[ -z "$ZONE" ]]; then
        echo "ZONE environment variable not found. Exiting.."
        exit 1
    else
        echo "Setting region to $REGION and zone to $ZONE."
        echo "zone = \"$ZONE\"" >> /usr/primary/tf.auto.tfvars
        echo "region = \"$REGION\"" >> /usr/primary/tf.auto.tfvars
    fi

    # setting instance count
    if [[ -z "$INSTANCE_COUNT" ]]; then
        echo "INSTANCE_COUNT environment variable not found. Default value is 1"
        export INSTANCE_COUNT=1
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
    if [[ -z "$IMAGE_FAMILY_NAME" ]]; then
        if [[ -z "$IMAGE_NAME" ]]; then
            echo "IMAGE_NAME environment variable not found. Default imafe family pytorch-1-12-gpu-debian-10 will be used."
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

    # setting image name
    if [[ -z "$SLEEP_DURATION_SEC" ]]; then
        echo "SLEEP_DURATION_SEC environment variable not found. Default value is 300."
        export SLEEP_DURATION_SEC=300
    fi
}