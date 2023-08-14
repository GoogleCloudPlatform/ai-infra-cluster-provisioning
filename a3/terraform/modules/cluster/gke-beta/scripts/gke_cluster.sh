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
    echo "checking if cluster '${cluster_name}' already exists" >&2
    ! gcloud container clusters describe "${cluster_name}" \
        --project="${project_id}" \
        --region="${region}" || {
        echo "cluster '${cluster_name}' already exists"
        return 1
    } >&2

    echo "creating cluster '${cluster_name}'" >&2
    gcloud beta container clusters create "${cluster_name}" \
        --cluster-version="${version}" \
        --enable-ip-alias \
        --enable-dataplane-v2 \
        --enable-multi-networking \
        --num-nodes='1' \
        --project="${project_id}" \
        --region="${region}" \
        --workload-pool="${project_id}.svc.id.goog" || {
        echo "failed to create cluster '${cluster_name}'"
        return 1
    } >&2

    echo "deleting node pool 'default-pool' in cluster '${cluster_name}'" >&2
    gcloud container node-pools delete 'default-pool' \
        --cluster="${cluster_name}" \
        --project="${project_id}" \
        --quiet \
        --region="${region}" || {
        echo "failed to delete node pool 'default-pool' from cluster '${cluster_name}'"
        return 1
    } >&2
}

gke_cluster::destroy () {
    echo "checking if cluster '${cluster_name}' still exists" >&2
    gcloud container clusters describe "${cluster_name}" \
        --project="${project_id}" \
        --region="${region}" || {
        echo "cluster '${cluster_name}' not found"
        return 0
    } >&2

    echo "deleting cluster '${cluster_name}'" >&2
    gcloud container clusters delete "${cluster_name}" \
        --project="${project_id}" \
        --quiet \
        --region="${region}" || {
        echo "failed to delete cluster '${cluster_name}'"
        return 1
    } >&2
}

main () {
    local -r action="${1:?}"
    local -r project_id="${2:?}"
    local -r cluster_name="${3:?}"
    local -r region="${4:?}"
    local -r version="${5:?}"

    case "${action}" in
        'create')
            gke_cluster::create || {
                echo "Failed to create GKE cluster ${cluster_name}."
                return 1
            } >&2
            echo "Successfully created GKE Cluster ${cluster_name}." >&2
            ;;
        'destroy')
            gke_cluster::destroy || {
                echo "Failed to destroy GKE cluster ${cluster_name}."
                return 1
            } >&2
            echo "Successfully destroyed GKE Cluster ${cluster_name}." >&2
            ;;
    esac
}

main "${@}"
