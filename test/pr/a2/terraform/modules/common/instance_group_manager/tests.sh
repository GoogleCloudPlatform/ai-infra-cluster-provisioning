. ./test/helpers.sh

a2::terraform::instance_group_manager::src_dir () {
    echo "${PWD}/a2/terraform/modules/common/instance_group_manager"
}

a2::terraform::instance_group_manager::input_dir () {
    echo "${PWD}/test/pr/a2/terraform/modules/common/instance_group_manager/input"
}

a2::terraform::instance_group_manager::output_dir () {
    echo "${PWD}/test/pr/a2/terraform/modules/common/instance_group_manager/output"
}

test::a2::terraform::instance_group_manager () {
    EXPECT_SUCCEED helpers::terraform_init "$(a2::terraform::instance_group_manager::src_dir)"
}

test::a2::terraform::instance_group_manager::simple_create_resource () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(a2::terraform::instance_group_manager::input_dir)/simple.tfvars" mig >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(a2::terraform::instance_group_manager::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(a2::terraform::instance_group_manager::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(a2::terraform::instance_group_manager::output_dir)/resources.json" \
        "${tfshow}"
}
