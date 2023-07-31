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
    # Deploy the latest GPU device plugin
    kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/cmd/nvidia_gpu/device-plugin.yaml 
    
    # Install the drivers
    kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/nvidia-driver-installer/cos/daemonset-preloaded-latest.yaml

    #Install nccl plugin installer
    kubectl apply -f ${nccl_plugin_yaml_path}
}

kubernetes-setup::setup_ksa () {
    echo "Binding IAM workload identity to default compute engine account ${gsa_name}"
    gcloud iam service-accounts add-iam-policy-binding ${gsa_name} \
        --role roles/iam.workloadIdentityUser \
        --member "serviceAccount:${project_id}.svc.id.goog[${ksa_namespace}/${ksa_name}]"
    
    echo "Annotating default k8s service account to compute engine account ${gsa_name}"
    kubectl create serviceaccount ${ksa_name} --namespace ${ksa_namespace}
    kubectl annotate serviceaccount ${ksa_name} --namespace ${ksa_namespace} \
        iam.gke.io/gcp-service-account=${gsa_name}
}

main () {
    local -r project_id="${1:?}"
    local -r gsa_name="${2:?}"
    local -r ksa_name="${3:?}"
    local -r ksa_namespace="${4:?}"
    local -r nccl_plugin_yaml_path="${5:?}"

    kubernetes-setup::install_drivers
    kubernetes-setup::setup_ksa
}

main "${@}"