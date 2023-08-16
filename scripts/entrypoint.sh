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

. ./scripts/entrypoint_helpers.sh

main () {

    # Environment/arguments setup

    local arg_action arg_cluster arg_machine_type
    local opt_backend_bucket opt_quiet
    local arg_var_file="${PWD}/input/terraform.tfvars"
    {
        entrypoint_helpers::parse_args "${@}" \
        && entrypoint_helpers::validate_args
    } \
    || { echo; entrypoint_helpers::get_usage; return 1; } >&2

    local -r module_path="$(
        entrypoint_helpers::module_path \
            "${arg_machine_type}" \
            "${arg_cluster}")"
    local -r tmp_var_file=$(mktemp)
    cp "${arg_var_file}" "${tmp_var_file}"

    # Auth setup

    entrypoint_helpers::ensure_auth_token \
        "${tmp_var_file}" || {
            echo 'Failed to set up auth token.'
            return 1
        } >&2

    # Backend setup

    local -r deployment_path=$(
        entrypoint_helpers::setup_backend \
            "${arg_cluster}" \
            "${tmp_var_file}" \
            "${module_path}/backend.tf" \
            "${opt_backend_bucket}") || {
        echo 'Failed to set up backend.'
        return 1
    } >&2
    echo "Terraform backend setup at '${deployment_path}'." >&2

    # Logging setup

    local -r log_file=$(mktemp)
    local -r stdout_pipe=$(mktemp -u)
    mkfifo -m 600 "${stdout_pipe}"
    if [ "${opt_quiet}" = true ]; then
        cat >"${log_file}" <"${stdout_pipe}" &
    else
        tee "${log_file}" <"${stdout_pipe}" &
    fi
    local -r log_pid="${!}"

    # Call terraform

    local terraform_success=true
    case "${arg_action}" in
        'create')
            {
                entrypoint_helpers::create \
                "${arg_cluster}" \
                "${tmp_var_file}" \
                "${module_path}" \
                && echo "Successfully created Cluster...." >&2
            } || {
                echo "Failed to create Cluster...." >&2
                terraform_success=false
            }
            ;;
        'destroy')
            {
                entrypoint_helpers::destroy \
                "${arg_cluster}" \
                "${tmp_var_file}" \
                "${module_path}" \
                && echo "Successfully destroyed Cluster...." >&2
            } || {
                echo "Failed to destroy Cluster...." >&2
                terraform_success=false
            }
            ;;
    esac >"${stdout_pipe}"
    wait "${log_pid}"
    rm -f "${stdout_pipe}"

    # Copy files to GCS
    echo -e '\n========================================================\n' >&2
    echo "Copying tfvars to GCS bucket..." >&2
    gsutil cp \
        "${tmp_var_file}" \
        "${deployment_path}/terraform.tfvars" || {
        echo 'unable to upload tfvars to GCS bucket'
        return 1
    } >&2

    echo "Copying terraform logs to GCS bucket..." >&2
    gsutil cp \
        "${log_file}" \
        "${deployment_path}/terraform.log" || {
        echo 'unable to upload terraform logs to GCS bucket'
        return 1
    } >&2

    [ "${terraform_success}" = true ]
}

main "${@}"
