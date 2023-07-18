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
    -b|--backend-bucket
                The GCS path to use for storing terraform state. Example:
                'gs://bucketName/dirName' The default value if not provided is
                'gs://aiinfra-terraform-<project_id>' where '<project_id>' is
                read from 'var_file'
    -h|--help   Print this help message.
    -q|--quiet  Minimizes the terraform logging. It still shows the error if
                terraform fails to create/destroy resources. Terraform logs are
                copied to GCS bucket whether this flag is set or not

Parameters:
    action      Action to perform. Options are:
                - create: provisions a cluster on Google Cloud.
                - destroy: destroys the cluster created on Google Cloud
    cluster     Type of cluster to act on. Options are:
                - gke: Google Kubernetes Engine -- terraform/modules/cluster/gke
                - mig: Managed Instance Group -- terraform/modules/cluster/mig
                - mig-with-container: MIG with docker container --
                    terraform/modules/cluster/mig-with-container
                - slurm: Slurm Workload Manager -- terraform/modules/cluster/slurm
    var_file    Terraform variables file. Defaults to:
                '${PWD}/input/terraform.tfvars'
EOT
#                - gke-beta: Google Kubernetes Engine with beta features not yet
#                    supported by terraform -- terraform/modules/cluster/gke-beta
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
                -b|--backend-bucket)
                    opt_backend_bucket="${2}"
                    shift
                    ;;
                -h|--help)
                    echo "$(entrypoint_helpers::get_usage)"
                    exit 0
                    ;;
                -q|--quiet)
                    opt_quiet=true
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
                    ;;
                2)
                    arg_cluster="${1}"
                    ;;
                3)
                    arg_var_file="${1}"
                    ;;
                *)
                    echo >&2 "too many parameters starting at '${1}'"
                    return 1
                    ;;
            esac
            ((++parameter_index))
        fi
        shift
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
    local -r _array_name="${1}[@]"
    local -r _value_name="${2}[@]"
    local -r _array=("${!_array_name}")
    local -r _value=("${!_value_name}")

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

    declare -ar expected_clusters=(
        'gke'
        'gke-beta'
        'mig'
        'mig-with-container'
        'slurm'
    )
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
#   - `module_path`: path to the terraform module to create
# Output: none
# Exit status:
#   - 0: all terraform calls were successful
#   - 1: at least one terraform call failed
entrypoint_helpers::create () {
    local -r cluster="${1:?}"
    local -r var_file="${2:?}"
    local -r module_path="${3:?}"

    echo "Running terraform init..." >&2
    terraform -chdir="${module_path}" init -no-color || {
        echo "terraform init failure."
        return 1
    } >&2

    echo "Running terraform validate..." >&2
    terraform -chdir="${module_path}" validate -no-color || {
        echo "terraform validate failure."
        return 1
    } >&2

    echo "Running terraform plan..." >&2
    tfplan=$(mktemp)
    terraform -chdir="${module_path}" \
        plan -out="${tfplan}" -var-file="${var_file}" -no-color || {
        echo "terraform plan failure."
        return 1
    } >&2

    echo "Running terraform apply..." >&2
    terraform -chdir="${module_path}" \
        apply -auto-approve "${tfplan}" ${extra_tf_args} -no-color || {
        echo "terraform apply failure."
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
#   - `module_path`: path to the terraform module to destroy
# Output: none
# Exit status:
#   - 0: all terraform calls were successful
#   - 1: at least one terraform call failed
entrypoint_helpers::destroy () {
    local -r cluster="${1:?}"
    local -r var_file="${2:?}"
    local -r module_path="${3:?}"

    echo "Running terraform init..." >&2
    terraform -chdir="${module_path}" init -no-color || {
        echo "terraform init failure."
        return 1
    } >&2

    echo "Running terraform destroy..." >&2
    terraform -chdir="${module_path}" \
        apply -auto-approve -var-file="${var_file}" \
        -destroy -no-color || {
        echo "terraform destroy failure."
        return 1
    } >&2
}

# Reads a variable value from tfvars file
#
# Parameters:
#   - `var_name`: the variable name
# Output: the variable value
# Exit status:
#   - 0: value is parsed and printed
#   - 1: value either could not be parsed
entrypoint_helpers::get_tfvar () {
    local -r var_file="${1:?}"
    local -r var_name="${2:?}"

    local value=$(sed -n 's/ *'"${var_name}"' *= *"\(.*\)"/\1/p' "${var_file}")
    if [ -n "${value}" ]; then
        echo "${value}"
        return 0
    fi

    return 1
}

# Checks if a bucket exists and then creates it if it doesn't
#
# Parameters:
#   - `project_id`: GCP Project ID pertaining to the GCS bucket
#   - `bucket_name`: Name of the GCS bucket
# Output: none
# Exit status:
#   - 0: Either the bucket already existed or it just got created
#   - 1: The bucket did not exist and could not be created
entrypoint_helpers::ensure_bucket_exists () {
    local -r project_id="${1:?}"
    local -r bucket_name="${2:?}"

    echo "Checking if GCS bucket '${bucket_name}' exists..." >&2
    gcloud storage buckets list "gs://${bucket_name}" >/dev/null \
        --project="${project_id}" && {
        echo "GCS bucket found." >&2
        return 0
    }

    echo "Failed to find GCS bucket -- creating..." >&2
    gcloud storage buckets create "gs://${bucket_name}" >/dev/null \
        --project="${project_id}" \
        --uniform-bucket-level-access && {
        echo "GCS bucket '${bucket_name}' created." >&2
        return 0
    }

    echo "Failed to create GCS bucket." >&2
    return 1
}

# Get the bucket name from a full GCS URL. Example:
# 'gs://gce-ai-infra/aiinfra-terraform-gce-ai-infra/gcb-pr'
# -> 'gce-ai-infra'
#
# Parameters:
#   - `backend_path`: Full GCS URL
# Output: The bucket name
# Exit status:
#   - 0: bucket name was retrieved
#   - 1: URL is either malformed or without a bucket name
entrypoint_helpers::get_bucket_name_from_path () {
    local -r backend_path="${1:?}"

    declare -ar backend_parts=($(echo "${backend_path}" | sed 's/\// /g'))
    [ "${#backend_parts[@]}" -ge 2 ] && echo "${backend_parts[1]}"
}

# Get the bucket subdirectory from a full GCS URL. Example:
# 'gs://gce-ai-infra/aiinfra-terraform-gce-ai-infra/gcb-pr'
# -> 'aiinfra-terraform-gce-ai-infra/gcb-pr'
#
# Parameters:
#   - `backend_path`: Full GCS URL
# Output: The bucket subdir if it exists (else none)
# Exit status: 0
entrypoint_helpers::get_bucket_subdir_from_path () {
    local -r backend_path="${1:?}"

    declare -ar backend_parts=($(echo "${backend_path}" | sed 's/\// /g'))
    if [ "${#backend_parts[@]}" -ge 3 ]; then
        echo "${backend_parts[@]:2}" | sed 's/ /\//g'
    fi

    return 0
}

# Generate a terraform backend block.
#
# Parameters:
#   - `bucket_name`: The bucket name
#   - `bucket_subdir`: Subdir in the bucket for the tfstate
# Output: The terraform backend block
# Exit status: 0
entrypoint_helpers::generate_backend_block () {
    local -r bucket_name="${1:?}"
    local -r bucket_subdir="${2:?}"

    cat <<EOT
terraform {
    backend "gcs" {
        bucket = "${bucket_name}"
        prefix = "${bucket_subdir}"
    }
}
EOT
}

# This function:
# - checks if a state backend exists and creates it if it doesn't
# - creates a backend config file
# - propagates state backend to script backend in tfvars if necessary
# - copies the tfvars file to the backend
#
# Params:
#   - `cluster`: type of cluster
#   - `var_file`: tfvars file
#   - `backend_config_path`: path to terraform backend config file
#   - `opt_backend_path`: backend path possibly given by the user
# Output: Path to the deployment in the GCS bucket
# Exit status:
#   - 0: All actions succeeded
#   - 1: One of the actions failed
entrypoint_helpers::setup_backend () {
    local -r cluster="${1:?}"
    local -r var_file="${2:?}"
    local -r backend_config_path="${3:?}"
    local -r opt_backend_path="$(echo "${4}" | sed 's/\/*$//')"

    # String manipulation

    local -r project_id="$(entrypoint_helpers::get_tfvar "${var_file}" 'project_id')" || {
        echo "unable to find variable 'project_id' in var file '${var_file}'"
        return 1
    } >&2
    local -r resource_prefix="$(entrypoint_helpers::get_tfvar "${var_file}" 'resource_prefix')" || {
        echo "unable to find variable 'resource_prefix' in var file '${var_file}'"
        return 1
    } >&2
    local -r backend_path="${opt_backend_path:-"gs://aiinfra-terraform-${project_id}"}"
    local -r bucket_name="$(entrypoint_helpers::get_bucket_name_from_path "${backend_path}")"
    local -r given_subdir="$(entrypoint_helpers::get_bucket_subdir_from_path "${backend_path}")"
    local -r deployment_subdir="$(echo "${given_subdir}/${resource_prefix}-deployment" | sed 's/^\/*//')"

    # Actions

    entrypoint_helpers::ensure_bucket_exists "${project_id}" "${bucket_name}" || {
        echo "unable to find or create GCS bucket '${bucket_name}' in project '${project_id}'."
        return 1
    } >&2

    entrypoint_helpers::generate_backend_block >"${backend_config_path}" \
        "${bucket_name}" \
        "${deployment_subdir}"

    local deployment_full_path="gs://${bucket_name}/${deployment_subdir}"
    if {
        { [ "${cluster}" = 'mig' ] || [ "${cluster}" = 'slurm' ]; } \
        && {
            ! entrypoint_helpers::get_tfvar >/dev/null \
                "${var_file}" \
                startup_script_gcs_bucket_path
        }
    }; then
        echo -e "\nstartup_script_gcs_bucket_path = \"${deployment_full_path}\"" >>"${var_file}"
    fi

    echo "${deployment_full_path}"
}

# Checks if a auth token exists or prompts for authentication if it doesn't.
#
# Parameters:
#   - `var_file`: tfvars file
# Output: none
# Exit status:
#   - 0: auth token successfully ensured.
#   - 1: Failed to set up auth token.
entrypoint_helpers::ensure_auth_token () {
    local -r var_file="${1:?}"
    local -r project_id="$(entrypoint_helpers::get_tfvar "${var_file}" 'project_id')" || {
        echo "unable to find variable 'project_id' in var file '${var_file}'"
        return 1
    } >&2

    local -r auth_account="$(gcloud auth list --filter=status:ACTIVE --format="value(account)")" || {
        echo "Failed to get the auth accounts."
        return 1
    } >&2

    if [ -z "${auth_account}" ]; then
        echo "No authenticated account found."
        gcloud auth login --update-adc || {
            echo "Failed to authenticate user."
            return 1
        } >&2
    else
        echo "Logged in as ${auth_account}" >&2
    fi

    gcloud config set project "${project_id}" || {
        echo "Failed to set project_id to ${project_id}"
        return 1
    } >&2
}
