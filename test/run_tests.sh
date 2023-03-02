#!/bin/bash

. ./test/aiinfra-cluster/installation_scripts/install_cloud_ops_agent.sh
. ./test/aiinfra-cluster/terraform.sh

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

run_tests "${@}"
