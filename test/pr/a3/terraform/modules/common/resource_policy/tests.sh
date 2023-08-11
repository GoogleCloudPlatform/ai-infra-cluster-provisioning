. ./test/helpers.sh

resource_policy::src_dir () {
    echo "${PWD}/a3/terraform/modules/common/resource_policy"
}

resource_policy::input_dir () {
    echo "${PWD}/test/pr/a3/terraform/modules/common/resource_policy/input"
}

resource_policy::output_dir () {
    echo "${PWD}/test/pr/a3/terraform/modules/common/resource_policy/output"
}

test::terraform::resource_policy () {
    EXPECT_SUCCEED helpers::terraform_init "$(resource_policy::src_dir)"
}

test::terraform::resource_policy::simple_create_resource () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(resource_policy::input_dir)/simple.tfvars" mig >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(resource_policy::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(resource_policy::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(resource_policy::output_dir)/resources.json" \
        "${tfshow}"
}
