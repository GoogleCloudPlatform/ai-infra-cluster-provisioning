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
    local arg_action arg_cluster
    local arg_var_file="${PWD}/input/terraform.tfvars"
    local opt_backend_bucket='gs://aiinfra'
    {
        entrypoint_helpers::parse_args "${@}" \
        && entrypoint_helpers::validate_args
    } \
    || { echo; entrypoint_helpers::get_usage; return 1; } >&2

    case "${arg_action}" in
        'create')
            entrypoint_helpers::create "${arg_cluster}" "${arg_var_file}"
            ;;
        'destroy')
            entrypoint_helpers::destroy "${arg_cluster}" "${arg_var_file}"
            ;;
    esac
}

main "${@}"
