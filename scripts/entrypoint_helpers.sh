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
    -h|--help            Print this help message.
    -b|--backend-bucket  The GCS path to use for storing terraform state.
                         example: 'gs://bucketName/dirName'
                         The default value if not provided is 'gs://aiinfra-terraform-<project_id>'

Parameters:
    action      Action to perform. Options are:
                - create: provisions a cluster on Google Cloud.
                - destroy: destroys the cluster created on Google Cloud
    cluster     Type of cluster to act on. Options are:
                - gke: Google Kubernetes Engine -- terraform/modules/cluster/gke
                - mig: Managed Instange Group -- terraform/modules/cluster/mig
                - slurm: Slurm Workload Manager -- terraform/modules/cluster/slurm
    var_file    Terraform variables file. Defaults to:
                '${PWD}/input/terraform.tfvars'
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
                -b|--backend-bucket)
                    opt_backend_bucket="${2}"
                    shift
                    ;;
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
    local -r project_id="$(entrypoint_helpers::read_tfvars "project_id")"
    local -r resource_prefix="$(entrypoint_helpers::read_tfvars "resource_prefix")"

    echo "creating backend config"
    entrypoint_helpers::create_backend_config \
    || {
        echo "Failed to create backend config"
        return  1
    } >&2

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
    local -r project_id="$(entrypoint_helpers::read_tfvars "project_id")"
    local -r resource_prefix="$(entrypoint_helpers::read_tfvars "resource_prefix")"

    echo "creating backend config"
    entrypoint_helpers::create_backend_config \
    || {
        echo "skipping terraform destroy"
        return  0
    }

    echo "running terraform init"
    terraform -chdir="${module_path}" init || {
        echo "terraform init failure"
        return 1
    } >&2

    echo "running terraform destroy"
    terraform -chdir="${module_path}" \
        apply -auto-approve -var-file="${var_file}" \
        -destroy \
    || {
        echo "terraform destroy failure"
        return 1
    } >&2
}

# Reads a variable value from tfvars file
#
# Parameters:
#   - `var_name`: the variable name
# Output: the variable value
# Exit status: 0
entrypoint_helpers::read_tfvars () {
    local var_name="${1:?}"
    local value=`grep "^${var_name} " $var_file | awk '{print $NF}'`
    if [ -n $value ]; then
        echo $value | sed 's/"//g'
    fi
}

# This purpose of this function is
#   1. if --backend-bucket is specified in command line validate the GCS path.
#   2. if --backend-bucket is not specified in command line
#       a. use gs://aiinfra-terraform-${project_id} as default backend path
#       b. Create the bucket if not exist.
#   3. if the cluster type is mig or slurm, then
#       a. if startup_script_gcs_bucket_path does not exist in tfvars file, add backend-bucket as script-bucket.
#   4. if the cluster type is gke then NOOP.
#
# Parameters: none
# Output: none
# Exit status:
#   - 0: backend-bucket GCS path is valid and backend config successfully created.
#   - 1: backend-bucket GCS path is invalid
entrypoint_helpers::create_backend_config () {
    local -r backend_config_path="${module_path}"/backend.tf

    if [ -z "${opt_backend_bucket}" ]; then
        local -r backend_gcs_bucket="gs://aiinfra-terraform-${project_id}"
        list_tf_bucket_ret=0
        list_tf_bucket_out=`gcloud storage buckets list ${backend_gcs_bucket}` || list_tf_bucket_ret=$?
        if [ $list_tf_bucket_ret -eq 0 ]; then
            echo "GCS bucket for terraform state ${backend_gcs_bucket} exists."
        else
            echo "GCS bucket for terraform state ${backend_gcs_bucket} does not exist. Creating..."
            gcloud storage buckets create "${backend_gcs_bucket}" \
                --project="${project_id}" --default-storage-class="REGIONAL" \
                --uniform-bucket-level-access \
            || {
                echo "Failed to create bucket ${backend_gcs_bucket}."
                return 1
            }
        fi
    else
        local -r backend_gcs_bucket="${opt_backend_bucket}"
        if [[ ${backend_gcs_bucket: -1} == "/" ]]; then
            echo "ERROR...The backend-bucket $backend_gcs_bucket is in incorrect format. Remove trailing /"
            return 1
        fi

        gsutil ls "${backend_gcs_bucket}" \
        || {
            echo "ERROR...The backend-bucket ${backend_gcs_bucket} is not present."
            return 1
        }
    fi

    if [[ "$backend_gcs_bucket" =~ ^gs://([^/]*)/*(.*) ]]; then
        local bucket_name=${BASH_REMATCH[1]}
        if [[ -z "${BASH_REMATCH[2]}" ]]; then
            local deployment_path=$resource_prefix-deployment
        else
            local deployment_path=${BASH_REMATCH[2]}/$resource_prefix-deployment
        fi
        echo "The backend-bucket is ${backend_gcs_bucket}. Terraform bucket is $bucket_name. Terraform backend path is $deployment_path."
    else
        echo "ERROR...The backend-bucket ${backend_gcs_bucket} is in incorrect format."
        return 1
    fi

    echo "terraform {" > $backend_config_path
    echo "  backend \"gcs\" {" >> $backend_config_path
    echo "    bucket = \"$bucket_name\"" >> $backend_config_path
    echo "    prefix = \"$deployment_path\"" >> $backend_config_path
    echo "  }" >> $backend_config_path
    echo "}" >> $backend_config_path

    if [ "${cluster}" == "gke" ]; then 
        return 0
    fi

    if [ -z "$(entrypoint_helpers::read_tfvars "startup_script_gcs_bucket_path")" ]; then
        echo "startup_script_gcs_bucket_path = \"${backend_gcs_bucket}\"" >> $var_file
    fi
}