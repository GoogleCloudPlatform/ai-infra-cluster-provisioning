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

tcp-direct-setup::apply_setup () {
    gke_instances=($(gcloud compute instances list --filter="metadata.items[].filter(key:kube-labels).firstof(value):(cloud.google.com/gke-nodepool=${node_pool_name})" --format="value(NAME)"))
    echo "Found ${#gke_instances[@]} instances for the GKE node_pool ${node_pool_name}." >&2
    for vm in "${gke_instances[@]}"
    do
      echo "Applying TCPX setup commands for ${vm}." >&2
      {
        gcloud compute ssh --zone ${zone} ${vm} --command 'sudo iptables -I INPUT -p tcp -m tcp -j ACCEPT && sudo mount --bind /var/lib/tcpx /var/lib/tcpx && sudo mount -o remount,exec /var/lib/tcpx' \
        && echo "Successfully ran commands for ${vm}...." >&2
      } || {
        echo "Failed to run commands for ${vm}...." >&2
      } 
    done
}

main () {
    local -r node_pool_name="${1:?}"
    local -r zone="${2:?}"

    tcp-direct-setup::apply_setup
}