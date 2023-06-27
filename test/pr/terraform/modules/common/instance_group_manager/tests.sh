. ./test/helpers.sh

instance_group_manager::src_dir () {
    echo "${PWD}/terraform/modules/common/instance_group_manager"
}

instance_group_manager::input_dir () {
    echo "${PWD}/test/pr/terraform/modules/common/instance_group_manager/input"
}

instance_group_manager::output_dir () {
    echo "${PWD}/test/pr/terraform/modules/common/instance_group_manager/output"
}

test::terraform::instance_group_manager () {
    EXPECT_SUCCEED helpers::terraform_init "$(instance_group_manager::src_dir)"
}

test::terraform::instance_group_manager::simple_create_resource () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(instance_group_manager::input_dir)/simple.tfvars" mig >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(instance_group_manager::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(instance_group_manager::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(instance_group_manager::output_dir)/resources.json" \
        "${tfshow}"
}
