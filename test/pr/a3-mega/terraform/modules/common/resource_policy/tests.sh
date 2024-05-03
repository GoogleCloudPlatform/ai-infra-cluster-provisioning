. ./test/helpers.sh

a3-mega::terraform::resource_policy::src_dir () {
    echo "${PWD}/a3-mega/terraform/modules/common/resource_policy"
}

a3-mega::terraform::resource_policy::input_dir () {
    echo "${PWD}/test/pr/a3-mega/terraform/modules/common/resource_policy/input"
}

a3-mega::terraform::resource_policy::output_dir () {
    echo "${PWD}/test/pr/a3-mega/terraform/modules/common/resource_policy/output"
}

test::a3-mega::terraform::resource_policy () {
    EXPECT_SUCCEED helpers::terraform_init "$(a3-mega::terraform::resource_policy::src_dir)"
}

test::a3-mega::terraform::resource_policy::simple_create_resource () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(a3-mega::terraform::resource_policy::input_dir)/simple.tfvars" mig >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(a3-mega::terraform::resource_policy::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(a3-mega::terraform::resource_policy::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(a3-mega::terraform::resource_policy::output_dir)/resources.json" \
        "${tfshow}"
}
