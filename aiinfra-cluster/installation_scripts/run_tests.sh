TEST_REGEX='/^[_[:alpha:]]{1,} \(\) \{ # test [_[:alpha:]]{1,}/'
declare -a TEST_FILES=(
    ./install_cloud_ops_agent_tests.sh)

. <(cat "${TEST_FILES[@]}" \
    | awk '{
        if ($0 ~ '"${TEST_REGEX}"') { printf("test_%s_%s () {\n", $NF, $1) }
        else { print $0 }
    }')

run_tests () {
    local COLOR_GRN='\e[1;32m'
    local COLOR_RED='\e[0;31m'
    local COLOR_RST='\e[0m'

    cat "${TEST_FILES[@]}" \
    | awk "${TEST_REGEX}"'{print $NF, $1}' \
    | while read suite_and_case; do
        suite="${suite_and_case% *}"
        case="${suite_and_case#* }"
        test_name="${suite} ${case}"
        test_command="test_${suite}_${case}"
        if ${test_command}; then
            echo -e "${test_name} ${COLOR_GRN}succeeded${COLOR_RST}"
        else
            echo -e "${test_name} ${COLOR_RED}failed${COLOR_RST}"
        fi
    done
}

run_tests
