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
    echo "Checking if cluster '${cluster_name}' already exists..." >&2

    local -r matching_clusters=$(
        gcloud container clusters list \
            --filter="name<=${cluster_name} AND name>=${cluster_name}" \
            --format='value(name)' \
            --project="${project_id}" \
            --region="${region}" \
        | wc -l)
    [ "${matching_clusters}" -eq 0 ] || {
        echo "Cluster '${cluster_name}' already exists."
        return 1
    } >&2

    # TODO: enable after adding variables for secondary ranges when using existing network
    # echo "Updating default subnet" >&2
    # gcloud compute networks subnets update default \
    #   --region "${region}" \
    #   --add-secondary-ranges="${cluster_name}-pods=10.150.0.0/21,${cluster_name}-services=10.150.8.0/21"
    #
    # Then add this to 'cluster create' command
    #    --cluster-secondary-range-name="${cluster_name}-pods" \
    #    --services-secondary-range-name="${cluster_name}-services" \

    echo "Creating cluster '${cluster_name}'..." >&2
    gcloud beta container clusters create "${cluster_name}" \
        --no-enable-autoupgrade \
        --no-enable-shielded-nodes \
        --enable-dataplane-v2 \
        --region="${region}" \
        --enable-ip-alias \
        --enable-multi-networking \
        --num-nodes='15' \
        --cluster-version="${version}" \
        --project="${project_id}" \
        --network="${network_name}" \
        --subnetwork="${subnetwork_name}" \
        --workload-pool="${project_id}.svc.id.goog" || {
        echo "Failed to create cluster '${cluster_name}'."
        return 1
    } >&2
}

gke_cluster::destroy () {
    echo "Checking if cluster '${cluster_name}' still exists..." >&2
    local -r matching_clusters=$(
        gcloud container clusters list \
            --filter="name<=${cluster_name} AND name>=${cluster_name}" \
            --format='value(name)' \
            --project="${project_id}" \
            --region="${region}" \
        | wc -l)
    [ "${matching_clusters}" -ne 0 ] || {
        echo "Cluster '${cluster_name}' not found."
        return 0
    } >&2

    echo "Deleting cluster '${cluster_name}'..." >&2
    gcloud container clusters delete "${cluster_name}" \
        --project="${project_id}" \
        --quiet \
        --region="${region}" || {
        echo "Failed to delete cluster '${cluster_name}'."
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
    local -r region="${4:?}"
    local -r version="${5:?}"
    local -r network_name="${6:?}"
    local -r subnetwork_name="${7:?}"

    case "${action}" in
        'create')
            gke_cluster::create
            ;;
        'destroy')
            gke_cluster::destroy
            ;;
        *)
            echo "invalid action '${action}'" >&2
            ;;
    esac
}

main "${@}"
