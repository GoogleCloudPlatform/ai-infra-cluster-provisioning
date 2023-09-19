. ./test/helpers.sh

a3::terraform::mig-cos::src_dir () {
    echo "${PWD}/a3/terraform/modules/cluster/mig-cos"
}

a3::terraform::mig-cos::input_dir () {
    echo "${PWD}/test/pr/a3/terraform/modules/cluster/mig-cos/input"
}

a3::terraform::mig-cos::output_dir () {
    echo "${PWD}/test/pr/a3/terraform/modules/cluster/mig-cos/output"
}

test::a3::terraform::mig-cos () {
    EXPECT_SUCCEED helpers::terraform_init "$(a3::terraform::mig-cos::src_dir)"
}

test::a3::terraform::mig-cos::simple_create_modules () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(a3::terraform::mig-cos::input_dir)/simple.tfvars" mig-cos >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(a3::terraform::mig-cos::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(a3::terraform::mig-cos::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(a3::terraform::mig-cos::output_dir)/modules.json" \
        "${tfshow}"
}

test::a3::terraform::mig-cos::multiple_create_modules () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(a3::terraform::mig-cos::input_dir)/multi.tfvars" mig-cos >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(a3::terraform::mig-cos::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(a3::terraform::mig-cos::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(a3::terraform::mig-cos::output_dir)/multimodules.json" \
        "${tfshow}"
}
