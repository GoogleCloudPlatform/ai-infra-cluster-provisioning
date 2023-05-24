. ./test/helpers.sh

instance_template::src_dir () {
    echo "${PWD}/terraform/modules/common/instance_template"
}

instance_template::input_dir () {
    echo "${PWD}/test/pr/terraform/modules/common/instance_template/input"
}

instance_template::output_dir () {
    echo "${PWD}/test/pr/terraform/modules/common/instance_template/output"
}

test::terraform::instance_template () {
    EXPECT_SUCCEED helpers::terraform_init "$(instance_template::src_dir)"
}

test::terraform::instance_template::simple_create_resource () {
    tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(instance_template::src_dir)" \
        "$(instance_template::input_dir)/simple.tfvars" \
        "${tfplan}"
    tfshow=$(mktemp)
    helpers::terraform_show "$(instance_template::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(instance_template::output_dir)/resources.json" \
        "${tfshow}"
}
