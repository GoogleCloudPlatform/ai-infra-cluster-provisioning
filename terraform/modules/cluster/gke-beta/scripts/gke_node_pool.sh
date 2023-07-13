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

gke_node_pool::create () {
    gcloud container node-pools describe ${node_pool_name} --cluster ${cluster_name} --region ${region} \
    || gcloud container node-pools create ${node_pool_name} --cluster ${cluster_name} --region ${region}
}

gke_node_pool::destroy () {
    gcloud container node-pools describe ${node_pool_name} --cluster ${cluster_name} --region ${region} \
    && gcloud container node-pools delete ${node_pool_name} --cluster ${cluster_name} --region ${region} --quiet
}

main () {
    local -r action="${1:?}"
    local -r cluster_name="${2:?}"
    local -r node_pool_name="${3:?}"
    local -r region="${4:?}"

    case "${action}" in
        'create')
            {
                gke_node_pool::create \
                && echo "Successfully created GKE node pool ${node_pool_name}...." >&2
            } || {
                echo "Failed to create GKE node pool ${node_pool_name}...." >&2
            }
            ;;
        'destroy')
            {
                gke_node_pool::destroy \
                && echo "Successfully destroyed GKE node pool ${node_pool_name}...." >&2
            } || {
                echo "Failed to destroy GKE node pool ${node_pool_name}...." >&2
            }
            ;;
    esac
}

main "${@}"