. ./test/helpers.sh

readonly SRC_DIR='/usr/primary'
# needs to be PWD because of the -chdir in the terraform commands
readonly DATA_DIR="${PWD}/test/aiinfra-cluster/cases"

skip::test::aiinfra-cluster::fmt () {
    EXPECT_SUCCEED terraform fmt -check -recursive /usr/primary
}

terraform_plan () {
    local -r var_file="${1}"
    local -r tmp_file="${2}"
    terraform -chdir="${SRC_DIR}" plan \
        -no-color -json -parallelism=$(nproc) -lock=false \
        -var-file="${var_file}" -out="${tmp_file}" >/dev/null
}

terraform_show () {
    local -r tmp_file="${1}"
    terraform -chdir="${SRC_DIR}" show -no-color -json "${tmp_file}"
}

json_contains () {
    element_file="${1}"
    input_file="${2}"
    # reference for `contains(element)` function:
    # https://stedolan.github.io/jq/manual/#Builtinoperatorsandfunctions
    jq "if contains($(cat ${element_file})) then empty else halt_error end" \
        "${input_file}"
}

test::aiinfra-cluster::passes_on_default_vars () {
    tfplan=$(mktemp)
    EXPECT_SUCCEED terraform_plan \
        "${DATA_DIR}/passes_on_default_vars.tfvars" \
        "${tfplan}"
    EXPECT_SUCCEED json_contains \
        "${DATA_DIR}/passes_on_default_vars.json" \
        <(terraform_show "${tfplan}")
}

test::aiinfra-cluster::fails_on_empty_vars () {
    EXPECT_FAIL terraform_plan \
        "${DATA_DIR}/fails_on_empty_vars.tfvars" \
        "$(mktemp)"
    #| jq 'if ."@level" == "error" then halt_error else empty end'
}
