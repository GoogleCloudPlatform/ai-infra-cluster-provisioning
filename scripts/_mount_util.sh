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
# method to add terraform modules to mount gcs bucket
#
_expand_mount_gcs_bucket() {
    mountGcsModule=""
    mountGcsScript=""

    # default value of copy directory path on the vm is /usr/aiinfra/copy.
    if [[ -z "$GCS_MOUNT_LIST" ]]; then
        echo "No GCS buckets found to mount."
    else
        local count=1
        for val in ${GCS_MOUNT_LIST//,/ }
        do
            if [[ -n ${val} ]] && [[ "$val" =~ .*":".* ]]; then
                ((count++))
                bucketName=${val%:*}
                mountpath=${val#*:}
                modulename=gcsfs$count
                echo "Setting up bucket $bucketName to mount at $mountpath."
                mountGcsModule+="module \"$modulename\" {\n"
                mountGcsModule+="    source        = \"github.com/GoogleCloudPlatform/hpc-toolkit//modules/file-system/pre-existing-network-storage//?ref=c1f4a44\"\n"
                mountGcsModule+="    fs_type       = \"gcsfuse\"\n"
                mountGcsModule+="    mount_options = \"defaults,_netdev,implicit_dirs\"\n"
                mountGcsModule+="    remote_mount  = \"$bucketName\"\n"
                mountGcsModule+="    local_mount   = \"$mountpath\"\n"
                mountGcsModule+="}\n"

                mountGcsScript+=", module.$modulename.client_install_runner\n"
                mountGcsScript+=", module.$modulename.mount_runner\n"
            fi
        done
    fi

    sed -i 's|__REPLACE_GCS_BUCKET_MOUNT_MODULE__|'"$mountGcsModule"'|' /usr/primary/main.tf
    sed -i 's|__REPLACE_GCS_BUCKET_MOUNT_SCRIPT__|'"$mountGcsScript"'|' /usr/primary/main.tf
}
