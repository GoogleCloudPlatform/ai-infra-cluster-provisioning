# Parse command line arguments for the test runner

# Print the usage help message for the entrypoint.
#
# Parameters: none
# Output: usage help message
# Exit status: 0
entrypoint_helpers::get_usage () {
    cat <<EOT
Usage: ./test/<test_set>/run.sh project_id [resource_prefix] [test_regex]

Options:
    -h|--help   Print this help message.

Parameters:
    project_id  String to replace the value of the project_id variable in all
                tfvars input files
    resource_prefix
                String to replace the value of the resource_prefix variable in
                all tfvars input files. Defaults to 'ci'.
    test_regex  Regex that will be used to filter which tests run. Defaults to
                'test::.*'.
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
                    arg_project_id="${1}"
                    ;;
                2)
                    arg_resource_prefix="${1}"
                    ;;
                3)
                    arg_test_regex="${1}"
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


# Run all tests in sourced files
#
# Parameters:
#   - `test_regex` (optional, default: 'test::.*'): run only tests matching
#   this regex
# Output:
#   - output of tests
#   - status of test running and whether it passed
#   - results -- how many passed, failed, or were skipped
# Exit status:
#   - 0: all tests either passed or were skipped
#   - 1: at least one test failed
runner::main () {
    local test_command

    local test_regex='test::.*'
    if [ "${#}" -eq 1 ]; then
        test_regex="${1}"
    fi

    print_test () {
        local -r test_command="${1:?}"
        local -r comment="${2:?}"
        echo -e "> ${test_command} ${comment}"
    }

    declare -ar test_commands=($(declare -F | awk "/${test_regex}/"'{print $NF}'))
    declare -a tests_skipped=()
    declare -a tests_passed=()
    declare -a tests_failed=()
    for test_command in "${test_commands[@]}"; do
        if grep -q '^skip::test::' <<< "${test_command}"; then
            skipped_test_command="${test_command#skip::}"
            tests_skipped+=("${skipped_test_command}")
            print_test "${skipped_test_command}" 'skipped'
            continue
        fi

        if ! grep -q '^test::' <<< "${test_command}"; then
            continue
        fi

        print_test "${test_command}" 'running...'
        if (${test_command}); then
            tests_passed+=("${test_command}")
            print_test "${test_command}" 'passed'
        else
            tests_failed+=("${test_command}")
            print_test "${test_command}" 'failed'
        fi
    done

    echo -e '\n==== RESULTS ===='

    local -r test_count=$((${#tests_passed[@]} + ${#tests_skipped[@]} + ${#tests_failed[@]}))
    echo -e "${#tests_passed[@]} of ${test_count} tests passed"

    if [ "${#tests_skipped[@]}" -ne 0 ]; then
        echo -e "${#tests_skipped[@]} of ${test_count} tests skipped"
        for skipped_test in "${tests_skipped[@]}"; do
            print_test "${skipped_test}" skipped
        done
    fi

    if [ "${#tests_failed[@]}" -ne 0 ]; then
        echo -e "${#tests_failed[@]} of ${test_count} tests failed"
        for failed_test in "${tests_failed[@]}"; do
            print_test "${failed_test}" failed
        done
    fi

    [ "${#tests_failed[@]}" -eq 0 ]
}

