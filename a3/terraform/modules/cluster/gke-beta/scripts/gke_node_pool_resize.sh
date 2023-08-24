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

gke_node_pool_resize::resize () {
    echo "Checking if node pool '${node_pool_name}' already exists in cluster '${cluster_name}'..." >&2
    local -r matching_node_pools=$(
        gcloud container node-pools list \
            --cluster="${cluster_name}" \
            --filter="name<=${node_pool_name} AND name>=${node_pool_name}" \
            --format='value(name)' \
            --project="${project_id}" \
            --region="${region}" \
        | wc -l)
    [ "${matching_node_pools}" -eq 1 ] || {
        echo "Node pool '${node_pool_name}' doesn't exist in cluster '${cluster_name}'."
        return 1
    } >&2

    echo "Resizing node pool '${node_pool_name}' in cluster '${cluster_name}'..." >&2
    gcloud beta container clusters resize "${cluster_name}" \
        --region="${region}" \
        --num-nodes="${node_count}" \
        --node-pool="${node_pool_name}" \
        --quiet || {
        echo "Failed to create node pool '${node_pool_name}' in cluster '${cluster_name}'."
        return 1
    } >&2
}

main () {
    local -r project_id="${1:?}"
    local -r cluster_name="${2:?}"
    local -r node_pool_name="${3:?}"
    local -r region="${4:?}"
    local -r node_count="${5:?}"

    gke_node_pool_resize::resize
}

main "${@}"
