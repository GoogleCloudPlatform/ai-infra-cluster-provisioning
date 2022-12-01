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
# method to create gcs bucket for terraform state
#
_create_gcs_bucket_for_terraform() {
    export TF_BUCKET_NAME=aiinfra-terraform-$PROJECT_ID
    list_tf_bucket_ret=0
    list_tf_bucket_out=`gcloud storage buckets list gs://$TF_BUCKET_NAME` || list_tf_bucket_ret=$?
    if [ $list_tf_bucket_ret -eq 0 ]; then
        echo "GCS bucket for terraform state $TF_BUCKET_NAME exists."
        echo "$list_tf_bucket_out"
    else
        echo "GCS bucket for terraform state $TF_BUCKET_NAME does not exists."
        if [[ "${ACTION,,}" == "destroy" ]]; then
            echo "Terraform state does not exist. 'Destroy' action cannot be performed. exit..."
            exit 1
        fi
        echo "Creating GCS bucket"
        create_tf_bucket_out=`gcloud storage buckets create gs://$TF_BUCKET_NAME --project=$PROJECT_ID --default-storage-class=REGIONAL --location=$REGION --uniform-bucket-level-access`
        create_tf_bucket_ret=$?
        echo "$create_tf_bucket_out"
        if [ $create_tf_bucket_ret -eq 0 ]; then
            echo "Created bucket $TF_BUCKET_NAME successfully."
        else
            echo "Failed to create bucket $TF_BUCKET_NAME with error $create_tf_bucket_ret."
            exit $create_tf_bucket_ret
        fi
    fi
    export TF_STATE_PATH=$NAME_PREFIX-deployment/terraform
}

#
# method to validate GCS path
#
_validate_gcs_path_for_terraform() {
    if [[ ${GCS_PATH: -1} == "/" ]]; then
        echo "ERROR...The GCS_PATH $GCS_PATH is in incorrect format. Remove trailing /"
        exit 1
    fi

    validate_gcs_bucket_ret=0
    validate_gcs_bucket_out=`gsutil ls $GCS_PATH` || validate_gcs_bucket_ret=$?
    if [ $validate_gcs_bucket_ret -eq 0 ]; then
        echo "GCS bucket validated. Return: $validate_gcs_bucket_out"
        if [[ "$GCS_PATH" =~ ^gs://([^/]*)/*(.*) ]]; then
            export TF_BUCKET_NAME=${BASH_REMATCH[1]}
            if [[ -z "${BASH_REMATCH[2]}" ]]; then
                export TF_STATE_PATH=terraform
            else
                export TF_STATE_PATH=${BASH_REMATCH[2]}/terraform
            fi
            echo "The GCS_PATH is $GCS_PATH. Terraform bucket is $TF_BUCKET_NAME. Terraform state path is $TF_STATE_PATH."
        else
            echo "ERROR...The GCS_PATH $GCS_PATH is in incorrect format."
            exit 1
        fi
    else
        echo "Failed to validate GCS path. Reason: $validate_gcs_bucket_out"
        exit $validate_gcs_bucket_ret
    fi
}