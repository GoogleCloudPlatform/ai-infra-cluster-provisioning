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
    export TF_BUCKET_NAME=$NAME_PREFIX-tf-bucket
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
    echo "gcs_path = \"$TF_BUCKET_NAME\"" >> /usr/primary/tf.auto.tfvars
}

#
# method to validate GCS path
#
_validate_gcs_path_for_terraform() {
    validate_gcs_bucket_ret=0
    validate_gcs_bucket_out=`gcloud storage buckets list $GCS_PATH --format="value(name)"` || validate_gcs_bucket_ret=$?
    if [ $validate_gcs_bucket_ret -eq 0 ]; then
        echo "GCS bucket $validate_gcs_bucket_out validated."
        export TF_BUCKET_NAME=$validate_gcs_bucket_out
        echo "gcs_path = \"$TF_BUCKET_NAME\"" >> /usr/primary/tf.auto.tfvars
    else
        echo "Failed to validate GCS path. Reason: $validate_gcs_bucket_out"
        exit $validate_gcs_bucket_ret
    fi
}