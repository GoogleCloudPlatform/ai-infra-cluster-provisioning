#!/bin/bash

# source all files containing tests
. ./test/terraform/modules/common/dashboard/tests.sh
. ./test/terraform/modules/common/instance_template/tests.sh
. ./test/terraform/modules/cluster/mig/tests.sh
. ./test/terraform/modules/common/network/tests.sh
#. ./test/aiinfra-cluster/installation_scripts/install_cloud_ops_agent.sh
#. ./test/aiinfra-cluster/terraform.sh
#. ./test/scripts/_env_var_util.sh

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
run_tests () {
    local -r COLOR_RST='\e[0m'
    local -r COLOR_BLD='\e[1m'
    local -r COLOR_RED='\e[1;31m'
    local -r COLOR_GRN='\e[1;32m'
    local -r COLOR_YLW='\e[1;33m'
    local test_command

    local test_regex='test::.*'
    if [ "${#}" -eq 1 ]; then
        test_regex="${1}"
    fi

    local pretty_comment
    declare -Ar pretty_wrap=(
        [failed]="${COLOR_RED}failed${COLOR_RST}"
        [passed]="${COLOR_GRN}passed${COLOR_RST}"
        [running]="${COLOR_BLD}running...${COLOR_RST}"
        [skipped]="${COLOR_YLW}skipped${COLOR_RST}"
    )
    print_test () {
        local -r comment="${1}"
        local -r test_command="${2}"
        echo -e "> ${test_command} ${pretty_wrap[$comment]}"
    }

    declare -ar test_commands=($(declare -F | awk "/${test_regex}/"'{print $NF}'))
    declare -a tests_skipped=()
    declare -a tests_passed=()
    declare -a tests_failed=()
    for test_command in "${test_commands[@]}"; do
        if grep -q '^skip::test::' <<< "${test_command}"; then
            skipped_test_command="${test_command#skip::}"
            tests_skipped+=("${skipped_test_command}")
            print_test skipped "${skipped_test_command}"
            continue
        fi

        if ! grep -q '^test::' <<< "${test_command}"; then
            continue
        fi

        print_test running "${test_command}"
        if (${test_command}); then
            tests_passed+=("${test_command}")
            print_test passed "${test_command}"
        else
            tests_failed+=("${test_command}")
            print_test failed "${test_command}"
        fi
    done

    echo -e '\n==== RESULTS ===='

    local -r test_count=$((${#tests_passed[@]} + ${#tests_skipped[@]} + ${#tests_failed[@]}))
    echo -e "${#tests_passed[@]} of ${test_count} tests ${pretty_wrap[passed]}"

    if [ "${#tests_skipped[@]}" -ne 0 ]; then
        echo -e "${#tests_skipped[@]} of ${test_count} tests ${pretty_wrap[skipped]}"
        for skipped_test in "${tests_skipped[@]}"; do
            print_test skipped "${skipped_test}"
        done
    fi

    if [ "${#tests_failed[@]}" -ne 0 ]; then
        echo -e "${#tests_failed[@]} of ${test_count} tests ${pretty_wrap[failed]}"
        for failed_test in "${tests_failed[@]}"; do
            print_test failed "${failed_test}"
        done
    fi

    [ "${#tests_failed[@]}" -eq 0 ]
}

run_tests "${@}"
