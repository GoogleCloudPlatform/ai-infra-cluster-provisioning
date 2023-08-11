. ./test/helpers.sh

mig-cos::src_dir () {
    echo "${PWD}/a3/terraform/modules/cluster/mig-cos"
}

mig-cos::input_dir () {
    echo "${PWD}/test/pr/a3/terraform/modules/cluster/mig-cos/input"
}

mig-cos::output_dir () {
    echo "${PWD}/test/pr/a3/terraform/modules/cluster/mig-cos/output"
}

test::terraform::a3::mig-cos () {
    EXPECT_SUCCEED helpers::terraform_init "$(mig-cos::src_dir)"
}

test::terraform::a3::mig-cos::simple_create_modules () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(mig-cos::input_dir)/simple.tfvars" mig-cos >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(mig-cos::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(mig-cos::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(mig-cos::output_dir)/modules.json" \
        "${tfshow}"
}
