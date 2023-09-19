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

kubernetes-setup::install_drivers () {
    echo 'Applying Nvidia driver installer' >&2
    kubectl apply -f 'https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/nvidia-driver-installer/cos/daemonset-preloaded-latest.yaml' || {
        echo 'Failed to apply Nvidia driver installer'
        return 1
    } >&2

    echo 'Applying fixup daemonset' >&2
    kubectl apply -f fixup_daemon_set.yaml || {
        echo 'Failed to apply fixup daemonset'
        return 1
    } >&2
}

kubernetes-setup::setup_ksa () {
    echo "Binding IAM workload identity to default compute engine account '${gsa_name}'" >&2
    gcloud iam service-accounts add-iam-policy-binding "${gsa_name}" \
        --role='roles/iam.workloadIdentityUser' \
        --member="serviceAccount:${project_id}.svc.id.goog[${ksa_namespace}/${ksa_name}]" || {
        echo "Failed to bind IAM workload identity to default compute engine account"
        return 1
    } >&2
    
    echo "Creating default k8s service account '${ksa_name}'" >&2
    kubectl create serviceaccount "${ksa_name}" \
        --namespace "${ksa_namespace}" || {
        echo "Failed to create default k8s service account"
        return 1
    } >&2

    echo "Annotating default k8s service account to compute engine account ${gsa_name}" >&2
    kubectl annotate serviceaccount "${ksa_name}" \
        --namespace "${ksa_namespace}" \
        "iam.gke.io/gcp-service-account=${gsa_name}" || {
        echo "Failed to annotate default k8s service account"
        return 1
    } >&2
}

main () {
    local -r project_id="${1:?}"
    local -r gsa_name="${2:?}"
    local -r ksa_name="${3:?}"
    local -r ksa_namespace="${4:?}"

    kubernetes-setup::install_drivers && kubernetes-setup::setup_ksa
}

main "${@}"
