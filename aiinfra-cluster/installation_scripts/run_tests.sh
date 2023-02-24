TEST_REGEX='/^[_[:alpha:]]{1,} \(\) \{ # test [_[:alpha:]]{1,}/'
declare -a TEST_FILES=(
    ./install_cloud_ops_agent_tests.sh)

preprocess_tests () {
    cat "${TEST_FILES[@]}" \
        | awk '{
            if ($0 ~ '"${TEST_REGEX}"') { printf("test_%s_%s () {\n", $NF, $1) }
            else { print $0 }
        }' \
        | sed \
            -e 's/\<EXPECT\>\(.*\)/if ! \1\; then echo >\&2 "--> "'\''&'\''; return 1; fi;/' \
            -e 's/\<EXPECT_FAIL\>\(.*\)/if 2>\/dev\/null \1\; then echo >\&2 "--> "'\''&'\''; return 1; fi;/' \
            -e 's/\<EXPECT_ARR_EQ\> \([^[:space:]]*\) \([^[:space:]]*\)/if [ "${#\1[@]}" -ne "${#\2[@]}" ]; then echo >\&2 "--> "'\''&'\''" -- unequal lengths (left: ${#\1[$i]}, right: ${#\2[$i]})"; return 1; fi; for i in $(seq 0 ${#\1[@]}); do if [ "${\1[$i]}" != "${\2[$i]}" ]; then echo >\&2 "--> "'\''&'\''" -- unequal elements (left: '\''${\1[$i]}'\'', right: '\''${\2[$i]}'\'')"; return 1; fi; done;/'
}

. <(preprocess_tests)

run_tests () {
    local COLOR_GRN='\e[1;32m'
    local COLOR_RED='\e[0;31m'
    local COLOR_RST='\e[0m'
    local failure=false

    while read suite_and_case; do
        suite="${suite_and_case% *}"
        case="${suite_and_case#* }"
        test_name="${suite} ${case}"
        test_command="test_${suite}_${case}"
        if ${test_command}; then
            echo -e "${test_name} ${COLOR_GRN}succeeded${COLOR_RST}"
        else
            echo -e "${test_name} ${COLOR_RED}failed${COLOR_RST}"
            failure=true
        fi
      done < <(cat "${TEST_FILES[@]}" | awk "${TEST_REGEX}"'{print $NF, $1}')

    [ "${failure}" == false ]
}

#preprocess_tests
run_tests
