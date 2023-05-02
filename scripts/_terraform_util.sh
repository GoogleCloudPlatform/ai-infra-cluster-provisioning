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
    apply_ret=0
    parallel_degree=""
    if [ "${ORCHESTRATOR_TYPE}" == "gke" ]; then
      parallel_degree="-parallelism=21"
    fi

    # change terraform verbosity based on MINIMIZE_TERRAFORM_LOGGING environment variable.
    if [[ -n "$MINIMIZE_TERRAFORM_LOGGING" ]]; then
        echo "Redirecting 'terraform apply' output to $TERRAFORM_LOG_PATH."
        terraform -chdir=/usr/primary apply -input=false -auto-approve $parallel_degree > $TERRAFORM_LOG_PATH || apply_ret=$?
    else
        terraform -chdir=/usr/primary apply -input=false -auto-approve $parallel_degree || apply_ret=$?
    fi

    if [ $apply_ret -eq 0 ]; then
        echo "Terraform apply finished successfully."
        _Display_connection_info
        # setup auto clean if environment variable is set
        if [[ -z "$CLEANUP_ON_EXIT" ]]; then
            echo "Cluster will be available after container exits."
        else
            if [[ "${CLEANUP_ON_EXIT}" == "yes" ]]; then
                echo "Cluster will be cleaned up during container exit..."
                export IS_CLEANUP_NEEDED="yes"
            fi
        fi
    elif [ "${ORCHESTRATOR_TYPE}" != "gke" ]; then
        echo "Terraform apply failed with error $apply_ret."
        migErr=$(gcloud compute instance-groups managed list-errors $NAME_PREFIX-mig --zone $ZONE)
        echo -e "${RED} $migErr ${NOP}"
        exit $apply_ret
    fi
}

#
# method to display jupyter notebook connection endpoint.
#
_Display_connection_info() {
    if [[ -n "$SHOW_PROXY_URL" && "${SHOW_PROXY_URL,,}" == "no" ]]; then
        echo "Not checking for proxy_url information."
    elif [[ "${IMAGE_PROJECT,,}" != "ml-images" && "${IMAGE_PROJECT,,}" != "deeplearning-platform-release" ]]; then
        echo "Jupyter notebook is not available in non-DLVM images."
    elif [[ -n "$ENABLE_NOTEBOOK" && "${ENABLE_NOTEBOOK,,}" == "false" ]]; then
        echo "Jupyter notebook is disabled."
    else
        for vm in $(gcloud compute instance-groups list-instances $NAME_PREFIX-mig --zone $ZONE --format="value(NAME)");
        do
            local attempt=1
            local max_attempts=20
            while [[ $attempt -lt $max_attempts ]]; 
            do
                local connStr=$(gcloud compute instances describe $vm --zone $ZONE --format='value[](metadata.items.proxy-url)')
                if [[ -z "$connStr" ]]; then
                    echo "Jupyter notebook endpoint not available yet. Sleeping 15 seconds."
                    sleep 15s
                    ((attempt++))
                else
                    echo "${vm} : https://${connStr}" >> /usr/connectiondata.txt
                    break
                fi
            done
        done
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

            # change terraform verbosity based on MINIMIZE_TERRAFORM_LOGGING environment variable.
            if [[ -n "$MINIMIZE_TERRAFORM_LOGGING" ]]; then
                echo "Redirecting 'terraform destroy' output to $TERRAFORM_LOG_PATH."
                terraform -chdir=/usr/primary destroy -input=false -auto-approve > $TERRAFORM_LOG_PATH || destroy_ret=$?
            else
                terraform -chdir=/usr/primary destroy -input=false -auto-approve || destroy_ret=$?
            fi

            del_state_ret=0
            if [ $destroy_ret -eq 0 ]; then
                echo "Successfully destroyed resources. Cleaning up the terraform state."
                gsutil rm -r gs://$TF_BUCKET_NAME/$TF_STATE_PATH/ || del_state_ret=$?
            fi
         else
            echo "Terraform destroy is already executed."
         fi
    fi
}

#
# method to perform terraform action to create or destroy cluster
#
_perform_terraform_action() {
    export TERRAFORM_LOG_PATH=/usr/terraformlog.txt
    if [[ "${ACTION,,}" == "create" ]]; then
        echo "Uploading environment variables to gs://$TF_BUCKET_NAME/$TF_DEPLOYMENT_PATH"
        printenv >> /usr/$NAME_PREFIX-env.list
        gsutil -m cp /usr/$NAME_PREFIX-env.list gs://$TF_BUCKET_NAME/$TF_DEPLOYMENT_PATH/$NAME_PREFIX-env.list
        echo "Parameter file location: gs://$TF_BUCKET_NAME/$TF_DEPLOYMENT_PATH/$NAME_PREFIX-env.list" >> /usr/info.txt 
        echo "Creating cluster..."
        terraform --version
        terraform -chdir=/usr/primary init -input=false
        _terraform_setup

        echo -e "${GREEN}=======================GPU cluster Information========================${NOC}"
        if [ -f "/usr/info.txt" ]; then
            cat /usr/info.txt
        fi

        if [ -f "/usr/connectiondata.txt" ]; then
            echo -e "${GREEN} Use below links to connect to the VMs: ${NOC}"
            cat /usr/connectiondata.txt
        fi
        echo -e "${GREEN}=======================================================================${NOC}"
        
    elif [[ "${ACTION,,}" == "destroy" ]]; then
        chk_statefile_ret=0
        gsutil ls gs://$TF_BUCKET_NAME/$TF_STATE_PATH/state/* || chk_statefile_ret=$?
        if [ $chk_statefile_ret -eq 0 ]; then
            echo "Destroying cluster..."
            export IS_CLEANUP_NEEDED="yes"
            terraform --version
            terraform -chdir=/usr/primary init -input=false
            _terraform_cleanup
        else
            echo "Terraform Sate file not found."
        fi
    elif [[ "${ACTION,,}" == "validate" ]]; then
        terraform --version
        terraform -chdir=/usr/primary init -input=false
        terraform -chdir=/usr/primary validate
    elif [[ "${ACTION,,}" == "plan" ]]; then
        terraform --version
        if ! terraform -chdir=/usr/primary init -input=false; then
            echo >&2 'terraform init failure'
            exit 1
        fi
        if ! terraform -chdir=/usr/primary plan -no-color -input=false; then
            echo >&2 'terraform plan failure'
            exit 1
        fi
    else
        echo "Action $ACTION is not supported..."
    fi

    if [ -f "$TERRAFORM_LOG_PATH" ]; then
        echo -e "${GREEN}Copying terraform output file from $TERRAFORM_LOG_PATH ${NOC}"
        gsutil -m cp $TERRAFORM_LOG_PATH gs://$TF_BUCKET_NAME/$TF_DEPLOYMENT_PATH/$NAME_PREFIX-terraform.log
    fi
}

#
# method to set up backend for terraform to manage state
#
_set_terraform_backend() {
    if [[ -z "$TERRAFORM_GCS_PATH" ]]; then
        _create_gcs_bucket_for_terraform
    else
        _validate_gcs_path_for_terraform
    fi

    echo "gcs_bucket_path = \"gs://$TF_BUCKET_NAME/$TF_DEPLOYMENT_PATH\"" >> /usr/primary/tf.auto.tfvars
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
    echo "    prefix = \"$TF_STATE_PATH/state\"" >> /usr/primary/backend.tf
    echo "  }" >> /usr/primary/backend.tf
    echo "}" >> /usr/primary/backend.tf

    echo "Terraform state file location: gs://$TF_BUCKET_NAME/$TF_STATE_PATH/state" >> /usr/info.txt
}
