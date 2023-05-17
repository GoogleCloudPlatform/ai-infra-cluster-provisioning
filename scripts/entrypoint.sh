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
    local arg_action
    local arg_cluster
    local arg_var_file
    {
        entrypoint::parse_args "${@}" \
        && entrypoint::default_args \
        && entrypoint::validate_args
    } \
    || { echo; entrypoint::get_usage; return 1; } >&2

    case "${arg_action}" in
        'create')
            entrypoint::create "${arg_cluster}" "${arg_var_file}"
            ;;
        'destroy')
            entrypoint::destroy "${arg_cluster}" "${arg_var_file}"
            ;;
    esac
}

main "${@}"
