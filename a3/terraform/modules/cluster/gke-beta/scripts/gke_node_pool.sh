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
    echo "checking if node pool '${node_pool_name}' already exists in cluster '${cluster_name}'" >&2
    ! gcloud container node-pools describe "${node_pool_name}" \
        --cluster="${cluster_name}" \
        --project="${project_id}" \
        --region="${region}" || {
        echo "node-pool '${node_pool_name}' already exists in cluster '${cluster_name}'"
        return 1
    } >&2

    echo "creating node pool '${node_pool_name}' in cluster '${cluster_name}'" >&2
    gcloud beta container node-pools create "${node_pool_name}" \
        --cluster="${cluster_name}" \
        --region="${region}" \
        --additional-node-network="network=${prefix}-gpu-0,subnetwork=${prefix}-gpu-0" \
        --additional-node-network="network=${prefix}-gpu-1,subnetwork=${prefix}-gpu-1" \
        --additional-node-network="network=${prefix}-gpu-2,subnetwork=${prefix}-gpu-2" \
        --additional-node-network="network=${prefix}-gpu-3,subnetwork=${prefix}-gpu-3" \
        --disk-type="${disk_type}" \
        --disk-size="${disk_size}" \
        --enable-gvnic \
        --host-maintenance-interval='PERIODIC' \
        --machine-type='a3-highgpu-8g' \
        --node-locations="${zone}" \
        --num-nodes="${node_count}" \
        --placement-policy ${resource_policy} \
        --project="${project_id}" \
        --scopes "https://www.googleapis.com/auth/cloud-platform" \
        --workload-metadata='GKE_METADATA' || {
        echo "failed to create node pool '${node_pool_name}' in cluster '${cluster_name}'"
        return 1
    } >&2
}

gke_node_pool::destroy () {
    echo "checking if node pool '${cluster_name}' still exists in cluster '${cluster_name}'" >&2
    gcloud container node-pools describe "${node_pool_name}" \
        --cluster="${cluster_name}" \
        --project="${project_id}" \
        --region="${region}" || {
        echo "node-pool '${node_pool_name}' not found in cluster '${cluster_name}'"
        return 0
    } >&2

    echo "deleting node pool '${node_pool_name}' from cluster '${cluster_name}'" >&2
    gcloud container node-pools delete "${node_pool_name}" \
        --cluster="${cluster_name}" \
        --project="${project_id}" \
        --quiet \
        --region="${region}" || {
        echo "failed to delete node pool '${node_pool_name}' from cluster '${cluster_name}'"
        return 1
    } >&2
}

main () {
    local -r action="${1:?}"
    local -r project_id="${2:?}"
    local -r cluster_name="${3:?}"
    local -r node_pool_name="${4:?}"
    local -r zone="${5:?}"
    local -r region="${6:?}"
    local -r node_count="${7:?}"
    local -r disk_type="${8:?}"
    local -r disk_size="${9:?}"
    local -r prefix="${10:?}"
    local -r resource_policy="${11:?}"

    case "${action}" in
        'create')
            gke_node_pool::create || {
                echo "Failed to create GKE node pool ${node_pool_name}."
                return 1
            } >&2
            echo "Successfully created GKE node pool ${node_pool_name}." >&2
            ;;
        'destroy')
            gke_node_pool::destroy || {
                echo "Failed to destroy GKE node pool ${node_pool_name}."
                return 1
            } >&2
            echo "Successfully destroyed GKE node pool ${node_pool_name}." >&2
            ;;
    esac
}

main "${@}"
