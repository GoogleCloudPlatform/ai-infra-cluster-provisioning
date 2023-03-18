get_error_prefix () {
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
    if ! "${@}"; then
        echo >&2 $(get_error_prefix EXPECT_SUCCEED "${*}") "failed"
        exit 1
    fi
    return 0
}

EXPECT_FAIL () {
    if "${@}"; then
        echo >&2 $(get_error_prefix EXPECT_FAIL "${*}") "succeeded"
        exit 1
    fi
    return 0
}

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

EXPECT_EQ () {
    local -r left="${1}"
    local -r right="${2}"
    if [ "${left}" -ne "${right}" ]; then
        echo >&2 $(get_error_prefix EXPECT_EQ "${left}" "${right}") "not equal"
        exit 1
    fi
    return 0
}

EXPECT_STR_EMPTY () {
    local -r str="${1}"
    if [ -n "${str}" ]; then
        echo >&2 $(get_error_prefix EXPECT_EQ "${str}") "not empty"
        exit 1
    fi
    return 0
}

EXPECT_STREQ () {
    local -r left="${1}"
    local -r right="${2}"
    if [ "${left}" != "${right}" ]; then
        echo >&2 $(get_error_prefix EXPECT_STREQ "${left}" "${right}") "not equal"
        exit 1
    fi
    return 0
}

EXPECT_FILE_REGULAR () {
    local -r filename="${1}"
    if ! [ -f "${filename}" ]; then
        echo >&2 $(get_error_prefix EXPECT_EQ "${str}") "not regular file"
        exit 1
    fi
    return 0
}
