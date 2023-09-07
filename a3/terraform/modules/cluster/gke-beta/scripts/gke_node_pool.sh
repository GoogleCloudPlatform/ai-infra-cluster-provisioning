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
    echo "Checking if node pool '${node_pool_name}' already exists in cluster '${cluster_name}'..." >&2
    local -r matching_node_pools=$(
        gcloud container node-pools list \
            --cluster="${cluster_name}" \
            --filter="name<=${node_pool_name} AND name>=${node_pool_name}" \
            --format='value(name)' \
            --project="${project_id}" \
            --region="${region}" \
        | wc -l)
    [ "${matching_node_pools}" -eq 0 ] || {
        echo "Node pool '${node_pool_name}' already exists in cluster '${cluster_name}'."
        return 1
    } >&2

    echo "Creating node pool '${node_pool_name}' in cluster '${cluster_name}'..." >&2
    gcloud beta container node-pools create "${node_pool_name}" \
        --cluster="${cluster_name}" \
        --region="${region}" \
        --node-locations="${zone}" \
        --project="${project_id}" \
        --machine-type="${machine_type}" \
        --num-nodes="${node_count}" \
        --disk-type="${disk_type}" \
        --disk-size="${disk_size}" \
        --ephemeral-storage-local-ssd count=16 \
        --scopes "https://www.googleapis.com/auth/cloud-platform" \
        --additional-node-network="${network_1}" \
        --additional-node-network="${network_2}" \
        --additional-node-network="${network_3}" \
        --additional-node-network="${network_4}" \
        --enable-gvnic \
        --host-maintenance-interval='PERIODIC' \
        --max-pods-per-node=36 \
        --placement-policy="${resource_policy}" \
        --no-enable-autoupgrade \
        --no-enable-autorepair \
        --workload-metadata='GKE_METADATA' || {
        echo "Failed to create node pool '${node_pool_name}' in cluster '${cluster_name}'."
        return 1
    } >&2
}

gke_node_pool::destroy () {
    echo "Checking if node pool '${node_pool_name}' still exists in cluster '${cluster_name}'..." >&2
    local -r matching_node_pools=$(
        gcloud container node-pools list \
            --cluster="${cluster_name}" \
            --filter="name<=${node_pool_name} AND name>=${node_pool_name}" \
            --format='value(name)' \
            --project="${project_id}" \
            --region="${region}" \
        | wc -l)
    [ "${matching_node_pools}" -ne 0 ] || {
        echo "Node pool '${node_pool_name}' not found in cluster '${cluster_name}'."
        return 0
    } >&2

    echo "Deleting node pool '${node_pool_name}' from cluster '${cluster_name}'..." >&2
    gcloud container node-pools delete "${node_pool_name}" \
        --cluster="${cluster_name}" \
        --project="${project_id}" \
        --quiet \
        --region="${region}" || {
        echo "Failed to delete node pool '${node_pool_name}' from cluster '${cluster_name}'."
        return 1
    } >&2
}

# This function:
# - if the action is 'create' then creates a GKE cluster using gcloud commands
#   - Checks if the cluster exists.
#   - Creates a GKE cluster if does not exist using custom COS image.
# - if the action is 'destroy' then deletes the GKE cluster using gcloud commands
#   - Checks if the cluster exists.
#   - Deletes the GKE cluster if exists.
#
# Params:
#   - `action`: The action to perform. Value can be 'create' or 'delete'
#   - `project_id`: The project ID to use to create the GKE cluster.
#   - `cluster_name`: The GKE cluster name.
#   - `region`: The region to create the GKE cluster in.
#   - `version`: The GKE cluster version.
#   - `network_name`: The GKE cluster network name.
#   - `subnetwork_name`: The GKE cluster subnetwork name.
# Output: none
# Exit status:
#   - 0: All actions succeeded
#   - 1: One of the actions failed
main () {
    local -r action="${1:?}"
    local -r project_id="${2:?}"
    local -r cluster_name="${3:?}"
    local -r node_pool_name="${4:?}"
    local -r zone="${5:?}"
    local -r region="${6:?}"
    local -r node_count="${7:?}"
    local -r machine_type="${8:?}"
    local -r disk_type="${9:?}"
    local -r disk_size="${10:?}"
    local -r prefix="${11:?}"
    local -r resource_policy="${12:?}"
    local -r network_1="${13:?}"
    local -r network_2="${14:?}"
    local -r network_3="${15:?}"
    local -r network_4="${16:?}"
    local -r image_name="${17:-}"
    local -r image_project="${18:-}"

    case "${action}" in
        'create')
            gke_node_pool::create
            ;;
        'destroy')
            gke_node_pool::destroy
            ;;
        *)
            echo "invalid action '${action}'" >&2
            ;;
    esac
}

main "${@}"
