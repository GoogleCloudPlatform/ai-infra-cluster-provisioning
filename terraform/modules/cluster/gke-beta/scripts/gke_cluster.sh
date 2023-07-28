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

gke_cluster::create () {
    gcloud container clusters describe ${cluster_name} --region ${region} \
    || { gcloud beta container clusters create ${cluster_name} --region ${region} \
      --project ${project_id} \
      --cluster-version ${version} \
      --enable-ip-alias \
      --enable-multi-networking \
      --enable-dataplane-v2 \
      --workload-pool=${project_id}.svc.id.goog \
      --num-nodes 1 \
      && gcloud container node-pools delete default-pool --cluster ${cluster_name} --region ${region} --quiet
    }
}

gke_cluster::destroy () {
    gcloud container clusters describe ${cluster_name} --region ${region} \
    && gcloud container clusters delete ${cluster_name} --region ${region} --project ${project_id} --quiet
}

main () {
    local -r action="${1:?}"
    local -r project_id="${2:?}"
    local -r cluster_name="${3:?}"
    local -r region="${4:?}"
    local -r version="${5:?}"

    export CLOUDSDK_API_ENDPOINT_OVERRIDES_CONTAINER=https://staging-container.sandbox.googleapis.com/

    case "${action}" in
        'create')
            {
                gke_cluster::create \
                && echo "Successfully created GKE Cluster ${cluster_name}...." >&2
            } || {
                echo "Failed to create GKE cluster ${cluster_name}...." >&2
                return 1
            }
            ;;
        'destroy')
            {
                gke_cluster::destroy \
                && echo "Successfully destroyed GKE Cluster ${cluster_name}...." >&2
            } || {
                echo "Failed to destroy GKE cluster ${cluster_name}...." >&2
                return 1
            }
            ;;
    esac
}

main "${@}"