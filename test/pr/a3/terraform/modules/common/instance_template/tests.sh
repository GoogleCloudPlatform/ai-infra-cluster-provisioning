. ./test/helpers.sh

instance_template::src_dir () {
    echo "${PWD}/a3/terraform/modules/common/instance_template"
}

instance_template::input_dir () {
    echo "${PWD}/test/pr/a3/terraform/modules/common/instance_template/input"
}

instance_template::output_dir () {
    echo "${PWD}/test/pr/a3/terraform/modules/common/instance_template/output"
}

test::terraform::a3::instance_template () {
    EXPECT_SUCCEED helpers::terraform_init "$(instance_template::src_dir)"
}

test::terraform::a3::instance_template::simple_create_resource () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(instance_template::input_dir)/simple.tfvars" mig >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(instance_template::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(instance_template::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(instance_template::output_dir)/resources.json" \
        "${tfshow}"
}
