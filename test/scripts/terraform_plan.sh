readonly ENV_DIR="./test/continuous"
readonly EXPECTED_DIR="./test/continuous/expected"

terraform_plan () {
    local -r env_list="${1}"
    local -r expected_output="${2}"
    EXPECT_SUCCEED [ -f "${env_list}" ]
    EXPECT_SUCCEED [ -f "${expected_output}" ]

    local -r actual_output="/out/tfplan"
    EXPECT_SUCCEED mkdir -p "$(dirname "${actual_output}")"

    export ACTION=plan
    . <(awk '{print "export", $0}' "${env_list}")
    EXPECT_SUCCEED bash /usr/entrypoint.sh

    local -r from='Terraform will perform the following actions:'
    local -r number='[[:digit:]]\{1,\}'
    local -r to="Plan: ${number} to add, ${number} to change, ${number} to destroy."
    filter () {
        local -r file_to_filter="${1}"
        sed -n \
            -e "/^${from}/,\${p;/^${to}/q}" \
            "${file_to_filter}" \
        | sed \
            -e '/"aiinfra-cluster" = "[a-f[:digit:]]\{,6\}"/d' \
            -e '/Command: metric.command_line],/d'
    }
    diff \
        <(filter "${expected_output}") \
        <(filter "${actual_output}") >&2
}

test::terraform_plan::simple () {
    EXPECT_SUCCEED terraform_plan \
        "${ENV_DIR}/simple-env.list" \
        "${EXPECTED_DIR}/simple.txt"
}

test::terraform_plan::disable_ops_agent () {
    EXPECT_SUCCEED terraform_plan \
        "${ENV_DIR}/disable-ops-agent-env.list" \
        "${EXPECTED_DIR}/disable-ops-agent.txt"
}
