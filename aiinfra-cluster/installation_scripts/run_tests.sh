declare -a TEST_FILES=(
    ./install_cloud_ops_agent_tests.sh)

err_prefix () {
    local fn_name="${1}"
    local params

    declare -a params=("${@:2}")
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
    local left_name="${1}"
    local right_name="${2}"
    local -n left="${left_name}"
    local -n right="${right_name}"
    local err_prefix=$(err_prefix EXPECT_ARREQ "${left_name}" "${right_name}")

    if [ "${#left[@]}" -ne "${#right[@]}" ]; then
        echo >&2 "${err_prefix}" "unequal lengths (${#left[@]}, ${#right[@]})"
        exit 1
    fi

    local arr_length="${#left[@]}"
    local i
    for i in $(seq 0 $((arr_length - 1))); do
        if [ "${left[$i]}" != "${right[$i]}" ]; then
            echo >&2 "${err_prefix}" "unequal elements [$i] (${left[$i]}, ${right[$i]})"
            exit 1
        fi
    done

    return 0
}

run_tests () {
    local COLOR_GRN='\e[1;32m'
    local COLOR_RED='\e[0;31m'
    local COLOR_RST='\e[0m'
    local failure=false
    local test_command

    while read test_command; do
        if (${test_command} >/dev/null); then
            echo -e "${test_command} ${COLOR_GRN}succeeded${COLOR_RST}"
        else
            echo -e "${test_command} ${COLOR_RED}failed${COLOR_RST}"
            failure=true
        fi
    done < <(declare -F | awk '/test::/{print $NF}')

    [ "${failure}" == false ]
}

. <(cat "${TEST_FILES[@]}")

run_tests
