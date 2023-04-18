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
get_error_prefix () {
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
        echo >&2 $(get_error_prefix EXPECT_SUCCEED "${*}") "failed"
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
        echo >&2 $(get_error_prefix EXPECT_FAIL "${*}") "succeeded"
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
    local -r error_prefix=$(get_error_prefix EXPECT_ARREQ "${left_name}" "${right_name}")

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
        echo >&2 $(get_error_prefix EXPECT_EQ "${left}" "${right}") "not equal"
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
        echo >&2 $(get_error_prefix EXPECT_EQ "${str}") "not empty"
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
        echo >&2 $(get_error_prefix EXPECT_STREQ "${left}" "${right}") "not equal"
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
        echo >&2 $(get_error_prefix EXPECT_EQ "${str}") "not regular file"
        exit 1
    fi
    return 0
}
