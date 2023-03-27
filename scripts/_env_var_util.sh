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


# Clean up environment variables whether they are valid or not. Right now this
# is just setting a few to lowercase to simplify string comparisons
#
# Parameters: none
# Output: none
# Exit status: 0
_env_var_util::clean () {
    ACTION="${ACTION,,}"
    NETWORK_CONFIG="${NETWORK_CONFIG,,}"
}

# Assert that environment variables are valid. An error will be printed for
# each invalid variable before returning.
#
# Parameters: none
# Output: none
# Exit status:
#   - 0: all environment variables are valid
#   - 1: at least one environment variable is invalid
_env_var_util::validate () {
    local valid=true

    {
        [ "${ACTION}" == 'create' ] \
        || [ "${ACTION}" == 'destroy' ] \
        || [ "${ACTION}" == 'plan' ] \
        || [ "${ACTION}" == 'validate' ];
    } || {
        echo "ACTION='${ACTION}'"
        echo "  - Must be one of ['create', 'destroy', 'plan', 'validate']."
        echo "  - This can also be set as an argument to the entrypoint."
        echo "  - If running in docker, this goes after the image tag"
        echo "    (docker run cluster-provision-image \${ACTION})."
        valid=false
    } >&2

    (PROJECT_ID="${PROJECT_ID:?}") || valid=false
    (NAME_PREFIX="${NAME_PREFIX:?}") || valid=false
    (ZONE="${ZONE:?}") || valid=false

    { [ -z "${IMAGE_FAMILY_NAME}" ] || [ -z "${IMAGE_NAME}" ]; } || {
        echo "IMAGE_FAMILY_NAME='${IMAGE_FAMILY_NAME}' and IMAGE_NAME='${IMAGE_NAME}'"
        echo "  - At least one of these must be unset or an empty string."
        valid=false
    } >&2

    {
        [ -z "${NETWORK_CONFIG}" ] \
        || [ "${NETWORK_CONFIG}" == 'default_network' ] \
        || [ "${NETWORK_CONFIG}" == 'new_network' ] \
        || [ "${NETWORK_CONFIG}" == 'multi_nic_network' ];
    } || {
        echo "NETWORK_CONFIG='${NETWORK_CONFIG}'"
        echo "  - Must be one of ['default_network', 'new_network', 'multi_nic_network']."
        valid=false
    } >&2

    [ "${valid}" == true ]
}

# For convenience, several environment variables have default values. If they
# are not set by the user (or set to null!), they are set here.
#
# Parameters: none
# Output: none
# Exit status: 0
_env_var_util::set_defaults () {
    REGION=${REGION:-"${ZONE%-?}"}
    [ "${ORCHESTRATOR_TYPE}" != "gke" ] && INSTANCE_COUNT=${INSTANCE_COUNT:-"1"}
    GPU_COUNT=${GPU_COUNT:-"2"}
    VM_TYPE=${VM_TYPE:-"a2-highgpu-2g"}
    METADATA="${METADATA:-"{}"}"
    ACCELERATOR_TYPE=${ACCELERATOR_TYPE:-"nvidia-tesla-a100"}
    LABELS="${LABELS:-"{}"}"
    [ -n "${IMAGE_NAME}" ] || {
        IMAGE_FAMILY_NAME=${IMAGE_FAMILY_NAME:-"pytorch-1-12-gpu-debian-10"};
    }
    DISK_SIZE_GB=${DISK_SIZE_GB:-"2000"}
    DISK_TYPE=${DISK_TYPE:-"pd-ssd"}
    NETWORK_CONFIG=${NETWORK_CONFIG:-"default_network"}
}

# Retrieves the service account for the project which has the format -- 
# `${project_num}-compute@developer.gserviceaccount.com` -- where `project_num`
# is the `projectNumber` corresponding to the project denoted by `project_id`
#
# Parameters:
#   - `project_id`: the name of the project in which the cluster will be
#   provisioned.
# Output: service account email address for the project
# Exit status:
#   - 0: printed successfully
#   - 1: error when calling gcloud commands
_env_var_util::get_project_email () {
    local -r project_id="${1}"
    local project_num

    get_project_num () {
        gcloud projects describe "${project_id}" --format="value(projectNumber)"
    }

    # go for gold
    project_num=$(get_project_num) || {
        # kinda long setup if failed
        echo 'unable to retrieve project number, reauthenticating...'
        gcloud auth login --update-adc || {
            echo 'gcloud authentication failed'
            return 1;
        }
        project_num="$(get_project_num)" || {
            echo 'failed to retrieve project information from gcloud'
            return 1;
        };
    } >&2

    echo "${project_num}-compute@developer.gserviceaccount.com"
}

# Prepares and validates environment variables in order for them to be
# converted to terraform variables in `_env_var_util::print_tfvars`.
#
# Parameters: none
# Output: none
# Exit status:
#   - 0: success
#   - 1: environment is invalid
_env_var_util::setup () {
    _env_var_util::clean \
    && _env_var_util::validate \
    && _env_var_util::set_defaults
}

# Print environment variables as terraform variables.
#
# Parameters:
#   - `project_email`: service account email address for project (typically
#   populated using `_env_var_util::get_project_email`).
#   - `uuid`: a unique identifier that will be prepended to the terraform
#   variable `labels` as `aiinfra-cluster="${uuid}"`
# Output: a tfvars file for the root module in `aiinfra-cluster`.
# Exit status:
#   - 0: success
#   - 1: missing parameter
_env_var_util::print_tfvars () {
    local -r project_email="${1}"
    local -r uuid="${2}"

    [ -n "${project_email}" ] || {
        echo >&2 "required parameter (1: project_email) empty"
        return 1;
    }
    [ -n "${uuid}" ] || {
        echo >&2 "required parameter (2: uuid) empty"
        return 1;
    }

    # print required and defaultable values
    cat <<EOF
project_id = "${PROJECT_ID}"
service_account = {
  email = "${project_email}"
  scopes = [
    "https://www.googleapis.com/auth/devstorage.read_write",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
    "https://www.googleapis.com/auth/servicecontrol",
    "https://www.googleapis.com/auth/service.management.readonly",
    "https://www.googleapis.com/auth/trace.append"
  ]
}
name_prefix = "${NAME_PREFIX}"
deployment_name = "${NAME_PREFIX}-dpl"
zone = "${ZONE}"
region = "${REGION}"
gpu_per_vm = ${GPU_COUNT}
machine_type = "${VM_TYPE}"
metadata = ${METADATA}
accelerator_type = "${ACCELERATOR_TYPE}"
instance_image = {
  family = "${IMAGE_FAMILY_NAME}"
  name = "${IMAGE_NAME}"
  project = "ml-images"
}
labels = { aiinfra-cluster="${uuid}", ${LABELS#*{}
disk_size_gb = ${DISK_SIZE_GB}
disk_type = "${DISK_TYPE}"
network_config = "${NETWORK_CONFIG}"
EOF

    # print optional values

    [ -n "${INSTANCE_COUNT}" ] && echo "instance_count = ${INSTANCE_COUNT}"
    [ -n "${GCS_MOUNT_LIST}" ] && echo "gcs_mount_list = \"${GCS_MOUNT_LIST}\""
    [ -n "${NFS_FILESHARE_LIST}" ] && echo "nfs_fileshare_list = \"${NFS_FILESHARE_LIST}\""
    [ -n "${ORCHESTRATOR_TYPE}" ] && echo "orchestrator_type = \"${ORCHESTRATOR_TYPE}\""
    [ -n "${STARTUP_COMMAND}" ] && echo "startup_command = \"${STARTUP_COMMAND}\""
    [ -n "${ENABLE_OPS_AGENT}" ] && echo "enable_ops_agent = \"${ENABLE_OPS_AGENT}\""
    [ -n "${ENABLE_NOTEBOOK}" ] && echo "enable_notebook = \"${ENABLE_NOTEBOOK}\""
    [ -n "${GKE_NODE_POOL_COUNT}" ] && echo "gke_node_pool_count = \"${GKE_NODE_POOL_COUNT}\""
    [ -n "${GKE_NODE_COUNT_PER_NODE_POOL}" ] && echo "gke_node_count_per_node_pool = ${GKE_NODE_COUNT_PER_NODE_POOL}"
    [ -n "${CUSTOM_NODE_POOL}" ] && echo "custom_node_pool = \"${CUSTOM_NODE_POOL}\""

    return 0
}
