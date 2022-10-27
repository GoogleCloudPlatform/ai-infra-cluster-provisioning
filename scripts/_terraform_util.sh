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
# method to perform terraform init and apply to create resources.
#
_terraform_setup() {
    terraform -chdir=/usr/primary validate
    terraform -chdir=/usr/primary apply -input=false -auto-approve
    tf_appl_ret_val=$?
    echo "Apply exit code $tf_appl_ret_val"
    if [ $tf_appl_ret_val -eq 0 ]; then
        echo "Terraform apply finished successfully."
        echo "Please use below commands to ssh into the VM instances."
        accountName=`gcloud config get-value account`
        username=${accountName%@*}
        for ((i=0; i<${INSTANCE_COUNT}; i++)); do
            echo "ssh -i ~/.ssh/google_compute_engine ${username}_google_com@nic0.${NAME_PREFIX}-$i.${ZONE}.c.${PROJECT_ID}.internal.gcpnode.com"
        done
        # setup auto clean is environment variable is set
        if [[ -z "$CLEANUP_ON_EXIT" ]]; then
            echo "Cluster will be available after container exits."
        else
            if [[ "${CLEANUP_ON_EXIT}" == "yes" ]]; then
                echo "Cluster will be cleaned up during container exit..."
                export IS_CLEANUP_NEEDED="yes"
            fi
        fi
    else
        echo "Terraform apply failed with error $tf_appl_ret_val."
        exit $tf_appl_ret_val
    fi
}

#
# method to perform terraform destroy on container exit.
#
_terraform_cleanup() {
    if [[ -z "$IS_CLEANUP_NEEDED" ]]; then
        echo "Terraform cleanup is not needed."
    else
        if [[ "${IS_CLEANUP_NEEDED}" == "yes" ]]; then
            export IS_CLEANUP_NEEDED="no"
            echo "Calling terraform destroy..."
            destroy_ret=0
            terraform -chdir=/usr/primary destroy -input=false -auto-approve || destroy_ret=$?
            del_state_ret=0
            if [ $destroy_ret -eq 0 ]; then
                echo "Successfully destroyed resources. Cleaning up the terraform state."
                gsutil rm -r gs://$TF_BUCKET_NAME/terraform/ || del_state_ret=$?
            fi
         else
            echo "Terraform destroy is alredy executed."
         fi
    fi
}

#
# method to perform terraform action to create or destroy cluster
#
_perform_terraform_action() {
    if [[ "${ACTION,,}" == "create" ]]; then
        echo "Creating cluster..."
        terraform --version
        terraform -chdir=/usr/primary init -input=false
        _terraform_setup
        if [[ ! -z "$CLEANUP_ON_EXIT" && "$CLEANUP_ON_EXIT" == "yes" ]]; then
            echo "Sleeping for $SLEEP_DURATION_SEC seconds in main script ....."
            sleep $SLEEP_DURATION_SEC & wait
        fi
    elif [[ "${ACTION,,}" == "destroy" ]]; then
        chk_statefile_ret=0
        `gsutil -q stat gs://$TF_BUCKET_NAME/terraform/state/*` || chk_statefile_ret=$?
        if [ $chk_statefile_ret -eq 0 ]; then
            echo "Destroying cluster..."
            export IS_CLEANUP_NEEDED="yes"
            terraform --version
            terraform -chdir=/usr/primary init -input=false
            _terraform_cleanup
        else
            echo "Terraform Sate file not found."
        fi
    else
        echo "Action $ACTION is not supported..."
    fi
}

#
# method to set up backend for terraform to manage state
#
_set_terraform_backend() {
    if [[ -z "$GCS_PATH" ]]; then
        _create_gcs_bucket_for_terraform
    else
        _validate_gcs_path_for_terraform
    fi

    echo "Terraform state management files are created on cloud storage."
    _create_terraform_backend_file
}

#
# method to create terraform backend file.
#
_create_terraform_backend_file() {
    echo "terraform {" > /usr/primary/backend.tf
    echo "  backend \"gcs\" {" >> /usr/primary/backend.tf
    echo "    bucket = \"$TF_BUCKET_NAME\"" >> /usr/primary/backend.tf
    echo "    prefix = \"terraform/state\"" >> /usr/primary/backend.tf
    echo "  }" >> /usr/primary/backend.tf
    echo "}" >> /usr/primary/backend.tf
}