#!/bin/bash

declare -a TEST_FILES=(
    ./test/scripts/install_cloud_ops_agent_tests.sh
    ./test/scripts/terraform_plan.sh)

err_prefix () {
    local -r fn_name="${1}"
    declare -ar params=("${@:2}")
    local params_str=""

    if [ "${#params[@]}" -ge 1 ]; then
        params_str="'${params[0]}'"
    fi

    local i
    for i in $(seq 1 $((${#params[@]} - 1))); do
        params_str="${params_str}, '${params[$i]}'"
    done

    echo "--> ${fn_name}(${params_str}):"
}

EXPECT_SUCCEED () {
    if ! "${@}" >/dev/null; then
        echo >&2 $(err_prefix EXPECT_SUCCEED "${*}") "failed"
        exit 1
    fi
    return 0
}

EXPECT_FAIL () {
    if "${@}" 2>/dev/null; then
        echo >&2 $(err_prefix EXPECT_FAIL "${*}") "succeeded"
        exit 1
    fi
    return 0
}

EXPECT_ARREQ () {
    local -r left_name="${1}"
    local -r right_name="${2}"
    local -nr left="${left_name}"
    local -nr right="${right_name}"
    local -r err_prefix=$(err_prefix EXPECT_ARREQ "${left_name}" "${right_name}")

    if [ "${#left[@]}" -ne "${#right[@]}" ]; then
        echo >&2 "${err_prefix}" "unequal lengths (${#left[@]}, ${#right[@]})"
        exit 1
    fi

    local -r arr_length="${#left[@]}"
    local i
    for i in $(seq 0 $((arr_length - 1))); do
        if [ "${left[$i]}" != "${right[$i]}" ]; then
            echo >&2 "${err_prefix}" "unequal elements [$i] (${left[$i]}, ${right[$i]})"
            exit 1
        fi
    done

    return 0
}

EXPECT_EQ () {
    local -r left="${1}"
    local -r right="${2}"
    if [ "${left}" -ne "${right}" ]; then
        echo >&2 $(err_prefix EXPECT_EQ "${left}" "${right}") "not equal"
        exit 1
    fi
    return 0
}

EXPECT_STR_EMPTY () {
    local -r str="${1}"
    if [ -n "${str}" ]; then
        echo >&2 $(err_prefix EXPECT_EQ "${str}") "not empty"
        exit 1
    fi
    return 0
}

EXPECT_FILE_REGULAR () {
    local -r filename="${1}"
    if ! [ -f "${filename}" ]; then
        echo >&2 $(err_prefix EXPECT_EQ "${str}") "not regular file"
        exit 1
    fi
    return 0
}

run_tests () {
    local -r COLOR_GRN='\e[1;32m'
    local -r COLOR_RED='\e[0;31m'
    local -r COLOR_RST='\e[0m'
    local failure=false
    local test_command

    local test_regex='test::.*'
    if [ "${#}" -eq 1 ]; then
        test_regex="${1}"
    fi

    declare -ar test_commands=($(declare -F | awk "/${test_regex}/"'{print $NF}'))
    for test_command in "${test_commands[@]}"; do
        if (${test_command} >/dev/null); then
            echo -e "${test_command} ${COLOR_GRN}succeeded${COLOR_RST}"
        else
            echo -e "${test_command} ${COLOR_RED}failed${COLOR_RST}"
            failure=true
        fi
    done

    [ "${failure}" == false ]
}

. <(cat "${TEST_FILES[@]}")

run_tests "${@}"
