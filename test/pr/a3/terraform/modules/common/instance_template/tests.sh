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

test::terraform::instance_template () {
    EXPECT_SUCCEED helpers::terraform_init "$(instance_template::src_dir)"
}

test::terraform::instance_template::simple_create_resource () {
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

test::terraform::instance_template::fails_on_guest_acc_with_acc_machine () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(instance_template::input_dir)/guest_acc_and_acc_machine.tfvars" mig >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_FAIL helpers::terraform_plan 2>/dev/null \
        "$(instance_template::src_dir)" \
        "${tfvars}" \
        "${tfplan}"
}
