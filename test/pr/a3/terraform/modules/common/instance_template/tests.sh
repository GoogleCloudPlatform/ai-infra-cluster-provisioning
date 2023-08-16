. ./test/helpers.sh

a3::terraform::instance_template::src_dir () {
    echo "${PWD}/a3/terraform/modules/common/instance_template"
}

a3::terraform::instance_template::input_dir () {
    echo "${PWD}/test/pr/a3/terraform/modules/common/instance_template/input"
}

a3::terraform::instance_template::output_dir () {
    echo "${PWD}/test/pr/a3/terraform/modules/common/instance_template/output"
}

test::a3::terraform::instance_template () {
    EXPECT_SUCCEED helpers::terraform_init "$(a3::terraform::instance_template::src_dir)"
}

test::a3::terraform::instance_template::simple_create_resource () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(a3::terraform::instance_template::input_dir)/simple.tfvars" mig >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(a3::terraform::instance_template::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(a3::terraform::instance_template::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(a3::terraform::instance_template::output_dir)/resources.json" \
        "${tfshow}"
}
