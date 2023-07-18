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
    || { gcloud beta container node-pools create ${node_pool_name} --cluster ${cluster_name} --region ${region} \
      --project ${project_id} \
      --node-locations ${zone} \
      --machine-type ${machine_type} \
      --num-nodes ${node_count} \
      --disk-type ${disk_type} \
      --disk-size ${disk_size} \
      --placement-type ${placement_type} \
      --workload-metadata=GKE_METADATA \
      --additional-node-network network=${prefix}-net-1,subnetwork=${prefix}-sub-1 \
      --additional-node-network network=${prefix}-net-2,subnetwork=${prefix}-sub-2 \
      --additional-node-network network=${prefix}-net-3,subnetwork=${prefix}-sub-3 \
      --additional-node-network network=${prefix}-net-4,subnetwork=${prefix}-sub-4 \
      --enable-gvnic \
      --scopes "https://www.googleapis.com/auth/cloud-platform" \
      --host-maintenance-interval PERIODIC \
      && kubectl get nodes --selector=cloud.google.com/gke-nodepool=${node_pool_name} --no-headers \
      | awk '{print $1}' \
      | xargs -I{} kubectl label node {} gke-no-default-nvidia-gpu-device-plugin=true
    }
}

gke_node_pool::destroy () {
    gcloud container node-pools describe ${node_pool_name} --cluster ${cluster_name} --region ${region} \
    && gcloud container node-pools delete ${node_pool_name} --cluster ${cluster_name} --region ${region} --quiet
}

main () {
    local -r action="${1:?}"
    local -r project_id="${2:?}"
    local -r cluster_name="${3:?}"
    local -r node_pool_name="${4:?}"
    local -r zone="${5:?}"
    local -r region="${6:?}"
    local -r machine_type="${7:?}"
    local -r node_count="${8:?}"
    local -r disk_type="${9:?}"
    local -r disk_size="${10:?}"
    #if [[ ${11} ]]; then
    #  local -r placement_type="COMPACT"
    #else
    #  local -r placement_type="UNSPECIFIED"
    #fi
    local -r placement_type=$(
      if [ "${11}" ]; then echo 'COMPACT'
      else echo 'UNSPECIFIED'; fi
    )
    local -r prefix="${12:?}"

    case "${action}" in
        'create')
            {
                gke_node_pool::create \
                && echo "Successfully created GKE node pool ${node_pool_name}...." >&2
            } || {
                echo "Failed to create GKE node pool ${node_pool_name}...." >&2
                return 1
            }
            ;;
        'destroy')
            {
                gke_node_pool::destroy \
                && echo "Successfully destroyed GKE node pool ${node_pool_name}...." >&2
            } || {
                echo "Failed to destroy GKE node pool ${node_pool_name}...." >&2
                return 1
            }
            ;;
    esac
}

main "${@}"