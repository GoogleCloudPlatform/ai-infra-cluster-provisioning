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

test::terraform::instance_template::fails_on_guest_acc_with_acc_machine () {
    tfplan=$(mktemp)
    EXPECT_FAIL helpers::terraform_plan 2>/dev/null \
        "$(instance_template::src_dir)" \
        "$(instance_template::input_dir)/guest_acc_and_acc_machine.tfvars" \
        "${tfplan}"
}
