. ./test/helpers.sh

readonly ENV_DIR="./test/continuous"
readonly EXPECTED_DIR="./test/continuous/expected"

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
