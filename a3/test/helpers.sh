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

# Format a prefix for errors printed by assertion functions so they all look the
# same.
#
# Parameters:
#   - `fn_name`: the name of the assertion function that is erroring
#   - `params` (variadic): the parameters to the assertion function
# Output: formatted error prefix
# Exit status: 0
helpers::get_error_prefix () {
    local -r fn_name="${1}"
    declare -ar params=("${@:2}")
    local params_str=""

    if [ "${#params[@]}" -ge 1 ]; then
        params_str="'${params[0]}'"
    fi

    local param
    for param in "${params[@]:1}"; do
        params_str+=", '${param}'"
    done

    echo "--> ${fn_name}(${params_str}):"
}

# Assert that a command succeeds with status == 0. If the command fails with
# status != 0, then print error to stderr and exit the shell with status 1.
#
# Parameters: the full command with parameters to test
# Output: none
# Exit status:
#   - 0: command succeeded
#   - 1: command failed (also exits shell)
EXPECT_SUCCEED () {
    if ! "${@}"; then
        echo >&2 $(helpers::get_error_prefix EXPECT_SUCCEED "${*}") "failed"
        exit 1
    fi
    return 0
}

# Assert that a command fails with status != 0. If the command succeeds with
# status == 0, then print error to stderr and exit the shell with status 1.
#
# Parameters: the full command with parameters to test
# Output: none
# Exit status:
#   - 0: command failed
#   - 1: command succeeded (also exits shell)
EXPECT_FAIL () {
    if "${@}"; then
        echo >&2 $(helpers::get_error_prefix EXPECT_FAIL "${*}") "succeeded"
        exit 1
    fi
    return 0
}

# Assert that two arrays are identical.
#
# Parameters:
#   - `left_name`: the **name** of one of the array variables
#   - `right_name`: the **name** of the other array variable
# Output: none
# Exit status:
#   - 0: arrays are identical
#   - 1: arrays differ (also exits shell)
EXPECT_ARREQ () {
    local -r left_name="${1}"
    local -r right_name="${2}"
    local -nr left="${left_name}"
    local -nr right="${right_name}"
    local -r error_prefix=$(helpers::get_error_prefix EXPECT_ARREQ "${left_name}" "${right_name}")

    if [ "${#left[@]}" -ne "${#right[@]}" ]; then
        echo >&2 "${error_prefix}" "unequal lengths (${#left[@]}, ${#right[@]})"
        exit 1
    fi

    local -r arr_length="${#left[@]}"
    local i
    for i in $(seq 0 $((arr_length - 1))); do
        if [ "${left[$i]}" != "${right[$i]}" ]; then
            echo >&2 "${error_prefix}" "unequal elements [$i] (${left[$i]}, ${right[$i]})"
            exit 1
        fi
    done

    return 0
}

# Assert that two integers are equal.
#
# Parameters:
#   - `left`: an integer
#   - `right`: another integer
# Output: none
# Exit status:
#   - 0: integers are equal
#   - 1: integers are not equal (also exits shell)
EXPECT_EQ () {
    local -r left="${1}"
    local -r right="${2}"
    if [ "${left}" -ne "${right}" ]; then
        echo >&2 $(helpers::get_error_prefix EXPECT_EQ "${left}" "${right}") "not equal"
        exit 1
    fi
    return 0
}

# Assert that a string is empty
#
# Parameters:
#   - `str`: the string to test
# Output: none
# Exit status:
#   - 0: string is empty
#   - 1: string is non-empty (also exits shell)
EXPECT_STR_EMPTY () {
    local -r str="${1}"
    if [ -n "${str}" ]; then
        echo >&2 $(helpers::get_error_prefix EXPECT_EQ "${str}") "not empty"
        exit 1
    fi
    return 0
}

# Assert that two strings are equal.
#
# Parameters:
#   - `left`: a string
#   - `right`: another string
# Output: none
# Exit status:
#   - 0: strings are equal
#   - 1: strings are not equal (also exits shell)
EXPECT_STREQ () {
    local -r left="${1}"
    local -r right="${2}"
    if [ "${left}" != "${right}" ]; then
        echo >&2 $(helpers::get_error_prefix EXPECT_STREQ "${left}" "${right}") "not equal"
        exit 1
    fi
    return 0
}

# Assert that a file exists and is a file (not directory)
#
# Parameters:
#   - `filename`: the path to the file
# Output: none
# Exit status:
#   - 0: file is regular
#   - 1: file either does not exist or is a directory (also exits shell)
EXPECT_FILE_REGULAR () {
    local -r filename="${1}"
    if ! [ -f "${filename}" ]; then
        echo >&2 $(helpers::get_error_prefix EXPECT_EQ "${str}") "not regular file"
        exit 1
    fi
    return 0
}

# Call `terraform init` on a module.
#
# Parameters:
#   - `src_dir`: path to the module directory
# Output: the stdout of `terraform init`
# Exit status:
#   - 0: terraform init succeeded
#   - 1: terraform init failed
helpers::terraform_init () {
    local -r src_dir="${1:?}"
    terraform -chdir="${src_dir}" init -no-color -reconfigure
}

# Call `terraform plan` and save tfplan to a file
#
# Parameters:
#   - `src_dir`: path to the module directory
#   - `var_file`: path to input tfvars file
#   - `out_file`: path to output tfplan file
# Output: none
# Exit status:
#   - 0: terraform plan produced zero errors (may have info or warn)
#   - 1: terraform plan produced one or more errors
helpers::terraform_plan () {
    local -r src_dir="${1:?}"
    local -r var_file="${2:?}"
    local -r out_file="${3:?}"
    ! jq -e 'select(."@level" == "error")' >&2 \
        <(terraform -chdir="${src_dir}" plan \
            -no-color -json -lock=false \
            -var-file="${var_file}" -out="${out_file}" \
        && echo '{"@level":"info","@message":"success"}')
}

# Call `terraform show` on a tfplan file
#
# Parameters:
#   - `src_dir`: path to the module directory
#   - `plan_file`: path to the tfplan file
# Output: terraform show output in json format
# Exit status:
#   - 0: `terraform show` exited successfully
#   - 1: `terraform show` exited unsuccessfully
helpers::terraform_show () {
    local -r src_dir="${1:?}"
    local -r plan_file="${2:?}"
    terraform -chdir="${src_dir}" show \
        -no-color -json "${plan_file}"
}

# Retrieve an output value from a tfplan file
#
# Parameters:
#   - `plan_json_file`: path to the file which is the output of `terraform show`
#   - `variable_name`: output variable name to retrieve
# Output: the value from the tfplan file
# Exit status:
#   - 0: the variable was found in the tfplan file
#   - 1: the variable was not found in the tfplan file
helpers::plan_output () {
    local -r plan_json_file="${1:?}"
    local -r variable_name="${2:?}"
    jq -rc ".planned_values.outputs.${variable_name}.value" "${plan_json_file}"
}

# Check if a json object contains another json object
#
# Parameters:
#   - `element_file`: file with a json object
#   - `input_file`: file with a json object which might be in `element_file`
# Output: if not found, `element_file`, else none
# Exit status:
#   - 0: `input_file` is contained within `element_file`
#   - 1: `input_file` is not contained within `element_file`
helpers::json_contains () {
    element_file="${1:?}"
    input_file="${2:?}"
    # reference for `contains(element)` function:
    # https://stedolan.github.io/jq/manual/#Builtinoperatorsandfunctions
    jq "if contains($(cat ${element_file})) then empty else halt_error end" \
        "${input_file}"
}

# Check if a json object does not contain another json object
#
# Parameters:
#   - `element_file`: file with a json object
#   - `input_file`: file with a json object which might be in `element_file`
# Output: if found, `element_file`, else none
# Exit status:
#   - 0: `input_file` is not contained within `element_file`
#   - 1: `input_file` is contained within `element_file`
helpers::json_omits () {
    element_file="${1:?}"
    input_file="${2:?}"
    # reference for `contains(element)` function:
    # https://stedolan.github.io/jq/manual/#Builtinoperatorsandfunctions
    jq "contains($(cat ${element_file})) | if not then empty else halt_error end" \
        "${input_file}"
}

# Append the project_id variable to a tfvars file
helpers::append_tfvars () {
    local -r var_file="${1:?}"
    local -r cluster_type="${2:?}"
    cat "${var_file}" \
        <(echo -e "\nproject_id = \"${runner_arg_project_id}\"") \
        <(echo -e "\nresource_prefix = \"${runner_arg_resource_prefix}-${cluster_type}\"")
}

