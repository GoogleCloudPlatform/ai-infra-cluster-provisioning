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

# Print the usage help message for the entrypoint.
#
# Parameters: none
# Output: usage help message
# Exit status: 0
entrypoint_helpers::get_usage () {
    cat <<EOT
Usage: ./scripts/entrypoint.sh [options] action cluster [var_file]

Options:
    -h|--help   Print this help message.

Parameters:
    action      Action to perform. Options are:
                - create: provisions a cluster on Google Cloud.
                - destroy: destroys the cluster created on Google Cloud
    cluster     Type of cluster to act on. Options are:
                - gke: Google Kubernetes Engine -- terraform/modules/cluster/gke
                - mig: Managed Instange Group -- terraform/modules/cluster/mig
                - slurm: Slurm Workload Manager -- terraform/modules/cluster/slurm
    var_file    Terraform variables file. Defaults to ./input/terraform.tfvars
EOT
}

# Parse the arguments/flags/options of the entrypoint.
#
# Parameters: all provided by the user
# Output: help messages and errors
# Exit status:
#   - 0: successfully read all args/flags/opts
#   - 1: unable to read at least one arg/flag/opt
#
# Note: will actually exit 0 (not return) when given a `help` flag
entrypoint_helpers::parse_args () {
    local parameter_index=1
    while [ "${#}" -gt 0 ]; do
        if grep -q '^-' <(echo "${1}"); then
            case "${1}" in
                -h|--help)
                    echo "$(entrypoint_helpers::get_usage)"
                    exit 0
                    ;;
                *)
                    echo >&2 "option '${1}' not supported"
                    return 1
                    ;;
            esac
        else
            case "${parameter_index}" in
                1)
                    arg_action="${1}"
                    shift
                    ;;
                2)
                    arg_cluster="${1}"
                    shift
                    ;;
                3)
                    arg_var_file="${1}"
                    shift
                    ;;
                *)
                    echo >&2 "too many parameters starting at '${1}'"
                    return 1
                    ;;
            esac
            ((++parameter_index))
        fi
    done
    return 0
}

# Check if an array contains a value. Print an error message if it doesn't
#
# Parameters:
#   - `_array_name`: name of the _array variable
#   - `_value_name`: name of the _value variable
# Output: none
# Exit status:
#   - 0: _array contains the _value
#   - 1: _array does not contain the _value
entrypoint_helpers::expect_contains () {
    local -r _array_name="${1}"
    local -r _value_name="${2}"
    local -nr _array="${_array_name}"
    local -nr _value="${_value_name}"

    [ "${#_array[@]}" -gt 0 ] || {
        echo "Array '${_array_name}' contains zero elements"
        return 1
    } >&2

    local _element
    for _element in "${_array[@]}"; do
        [ "${_element}" = "${_value}" ] && return 0;
    done

    local _array_pretty="'${_array[0]}'"
    for _element in "${_array[@]:1}"; do
        _array_pretty+=", '${_element}'"
    done
    {
        echo "${_value_name}='${_value}'"
        echo "  - Must be one of [${_array_pretty}]."
    } >&2

    return 1
}

# Assert that arguments are valid. An error will be printed for each invalid
# argument before returning.
#
# Parameters: none
# Output: none
# Exit status:
#   - 0: all args/flags/opts are valid
#   - 1: at least one arg/flag/opt is invalid
entrypoint_helpers::validate_args () {
    local valid=true

    declare -ar expected_actions=('create' 'destroy')
    entrypoint_helpers::expect_contains expected_actions arg_action || valid=false

    declare -ar expected_clusters=('gke' 'mig' 'slurm')
    entrypoint_helpers::expect_contains expected_clusters arg_cluster || valid=false

    [ -f "${arg_var_file}" ] || {
        echo "var_file='${arg_var_file}'"
        echo "  - Must be regular file"
        valid=false
    } >&2

    [ "${valid}" = true ]
}

# Get the path to a cluster module
#
# Parameters:
#   - `cluster`: type of cluster
# Output: path to the terraform module
# Exit status: 0
entrypoint_helpers::module_path () {
    local -r cluster="${1:?}"
    echo "./terraform/modules/cluster/${cluster}"
}

# Provision a cluster
#
# Parameters:
#   - `cluster`: type of cluster
#   - `var_file`: tfvars file
# Output: none
# Exit status:
#   - 0: all terraform calls were successful
#   - 1: at least one terraform call failed
entrypoint_helpers::create () {
    local -r cluster="${1:?}"
    local -r var_file="${2:?}"
    local -r module_path="$(entrypoint_helpers::module_path "${cluster}")"

    echo "running terraform init"
    terraform -chdir="${module_path}" init || {
        echo "terraform init failure"
        return 1
    } >&2

    echo "running terraform validate"
    terraform -chdir="${module_path}" validate || {
        echo "terraform validate failure"
        return 1
    } >&2

    echo "running terraform plan"
    tfplan=$(mktemp)
    terraform -chdir="${module_path}" \
        plan -out="${tfplan}" -var-file="${var_file}" \
    || {
        echo "terraform plan failure"
        return 1
    } >&2

    echo "running terraform apply"
    terraform -chdir="${module_path}" \
        apply -auto-approve \
        "${tfplan}" \
    || {
        echo "terraform apply failure"
        entrypoint_helpers::destroy "${cluster}" "${var_file}"

        rm -f "${tfplan}"
        return 1
    } >&2

    rm -f "${tfplan}"
    return 0
}

# Destroy a cluster
#
# Parameters:
#   - `cluster`: type of cluster
#   - `var_file`: tfvars file
# Output: none
# Exit status:
#   - 0: all terraform calls were successful
#   - 1: at least one terraform call failed
entrypoint_helpers::destroy () {
    local -r cluster="${1:?}"
    local -r var_file="${2:?}"
    local -r module_path="$(entrypoint_helpers::module_path "${cluster}")"

    echo "running terraform destroy"
    terraform -chdir="${module_path}" \
        apply -auto-approve -var-file="${var_file}" \
        -destroy \
    || {
        echo "terraform destroy failure"
        return 1
    } >&2

    return 0
}
