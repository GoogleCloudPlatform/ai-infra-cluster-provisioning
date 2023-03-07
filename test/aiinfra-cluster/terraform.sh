. ./test/helpers.sh

readonly ENV_DIR="./test/continuous"
readonly EXPECTED_DIR="./test/continuous/expected"

disabled::test::aiinfra-cluster::fmt () {
    EXPECT_SUCCEED terraform fmt -check -recursive /usr/primary
}

test::aiinfra-cluster::simple () {
    EXPECT_SUCCEED terraform_plan \
        "${ENV_DIR}/simple-env.list" \
        "${EXPECTED_DIR}/simple.txt"
}

test::aiinfra-cluster::disable_ops_agent () {
    EXPECT_SUCCEED terraform_plan \
        "${ENV_DIR}/disable-ops-agent-env.list" \
        "${EXPECTED_DIR}/disable-ops-agent.txt"
}
