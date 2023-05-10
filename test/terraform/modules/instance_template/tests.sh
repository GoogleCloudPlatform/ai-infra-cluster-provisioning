. ./test/helpers.sh

instance_template::src_dir () {
    echo "${PWD}/terraform/modules/instance_template"
}

instance_template::input_dir () {
    echo "${PWD}/test/terraform/modules/instance_template/input"
}

instance_template::output_dir () {
    echo "${PWD}/test/terraform/modules/instance_template/output"
}

test::terraform::instance_template () {
    EXPECT_SUCCEED terraform -chdir="$(instance_template::src_dir)" init -reconfigure
}

test::terraform::instance_template::fmt () {
    EXPECT_SUCCEED terraform -chdir="$(instance_template::src_dir)" fmt -check -recursive
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
