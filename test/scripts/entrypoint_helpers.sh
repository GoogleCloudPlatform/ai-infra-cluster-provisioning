. ./test/helpers.sh

. ./scripts/entrypoint_helpers.sh

test::entrypoint_helpers::expect_contains::fails_on_empty_array () {
    declare -ar arr=()
    local -r element=""
    EXPECT_FAIL entrypoint_helpers::expect_contains arr element
}

test::entrypoint_helpers::expect_contains::fails_on_element_missing () {
    declare -ar arr=("apple" "banana")
    local -r element="orange"
    EXPECT_FAIL entrypoint_helpers::expect_contains arr element
}

test::entrypoint_helpers::expect_contains::succeeds_on_element_present () {
    declare -ar arr=("apple" "banana")
    local -r element="apple"
    EXPECT_SUCCEED entrypoint_helpers::expect_contains arr element
}

test::entrypoint_helpers::parse_args::parses_no_args () {
    local arg_action arg_cluster arg_var_file
    EXPECT_SUCCEED entrypoint_helpers::parse_args
    EXPECT_STR_EMPTY "${arg_action}"
    EXPECT_STR_EMPTY "${arg_cluster}"
    EXPECT_STR_EMPTY "${arg_var_file}"
}

test::entrypoint_helpers::parse_args::parses_all_args () {
    local arg_action arg_cluster arg_var_file
    EXPECT_SUCCEED entrypoint_helpers::parse_args create mig ./custom.tfvars
    EXPECT_STREQ "${arg_action}" create
    EXPECT_STREQ "${arg_cluster}" mig
    EXPECT_STREQ "${arg_var_file}" ./custom.tfvars
}

test::entrypoint_helpers::parse_args::succeeds_on_help () {
    local arg_action arg_cluster arg_var_file
    (entrypoint_helpers::parse_args --help) || EXPECT_SUCCEED false
}

test::entrypoint_helpers::validate_args::fails_on_invalid_action () {
    local arg_action="invalid"
    local arg_cluster="mig"
    local arg_var_file="./test/scripts/entrypoint_helpers.sh"
    EXPECT_FAIL entrypoint_helpers::validate_args invalid mig ./custom.tfvars
}

test::entrypoint_helpers::validate_args::fails_on_invalid_cluster () {
    local arg_action="create"
    local arg_cluster="invalid"
    local arg_var_file="./test/scripts/entrypoint_helpers.sh"
    EXPECT_FAIL entrypoint_helpers::validate_args invalid mig ./custom.tfvars
}

test::entrypoint_helpers::validate_args::fails_on_invalid_var_file () {
    local arg_action="create"
    local arg_cluster="mig"
    local arg_var_file="invalid"
    EXPECT_FAIL entrypoint_helpers::validate_args invalid mig ./custom.tfvars
}

test::entrypoint_helpers::module_path::gets_path_to_cluster () {
    EXPECT_STREQ \
        "$(entrypoint_helpers::module_path mig)" \
        './terraform/modules/cluster/mig'
}
