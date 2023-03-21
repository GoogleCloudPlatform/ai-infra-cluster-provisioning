. ./test/helpers.sh

terraform::test::src_dir () {
    echo '/usr/primary'
}

terraform::test::data_dir () {
    # needs to be PWD because of the -chdir in the terraform commands
    echo "${PWD}/test/aiinfra-cluster/data"
}

# Helper functions

terraform::test::plan () {
    local -r var_file="${1}"
    local -r tmp_file="${2}"
    ! jq -e 'select(."@level" == "error")' >&2 \
        <(terraform -chdir="$(terraform::test::src_dir)" plan \
            -no-color -json -parallelism=$(nproc) -lock=false \
            -var-file="${var_file}" -out="${tmp_file}" \
        && echo '{"@level":"info","@message":"success"}')
}

terraform::test::show () {
    local -r tmp_file="${1}"
    terraform -chdir="$(terraform::test::src_dir)" show \
        -no-color -json "${tmp_file}"
}

terraform::test::json_contains () {
    element_file="${1}"
    input_file="${2}"
    # reference for `contains(element)` function:
    # https://stedolan.github.io/jq/manual/#Builtinoperatorsandfunctions
    jq "if contains($(cat ${element_file})) then empty else halt_error end" \
        "${input_file}"
}

# Test functions

skip::test::aiinfra-cluster::fmt () {
    EXPECT_SUCCEED terraform fmt -check -recursive /usr/primary
}

test::aiinfra-cluster::passes_on_default_vars () {
    tfplan=$(mktemp)
    EXPECT_SUCCEED terraform::test::plan \
        "$(terraform::test::data_dir)/passes_on_default_vars.tfvars" \
        "${tfplan}"
    EXPECT_SUCCEED terraform::test::json_contains \
        "$(terraform::test::data_dir)/passes_on_default_vars.json" \
        <(terraform::test::show "${tfplan}")
}

test::aiinfra-cluster::fails_on_empty_vars () {
    EXPECT_FAIL terraform::test::plan \
        "$(terraform::test::data_dir)/fails_on_empty_vars.tfvars" \
        "$(mktemp)" 2>/dev/null
    #| jq 'if ."@level" == "error" then halt_error else empty end'
}

skip::test::aiinfra-cluster::disable_ops_agent_removes_dashboard () {
    tfplan=$(mktemp)
    EXPECT_SUCCEED terraform::test::plan \
        "$(terraform::test::data_dir)/disable_ops_agent_removes_dashboard.tfvars" \
        "${tfplan}"
    tfshow=$(mktemp)
    terraform::test::show "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED terraform::test::json_contains \
        "$(terraform::test::data_dir)/disable_ops_agent_has_compute.json" \
        "${tfshow}"
    EXPECT_FAIL terraform::test::json_contains \
        "$(terraform::test::data_dir)/disable_ops_agent_removes_dashboard.json" \
        "${tfshow}"
}
