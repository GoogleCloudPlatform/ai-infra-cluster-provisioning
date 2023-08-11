. ./test/helpers.sh

dashboard::src_dir () {
    echo "${PWD}/a3/terraform/modules/common/dashboard"
}

dashboard::input_dir () {
    echo "${PWD}/test/pr/a3/terraform/modules/common/dashboard/input"
}

dashboard::output_dir () {
    echo "${PWD}/test/pr/a3/terraform/modules/common/dashboard/output"
}

test::terraform::dashboard () {
    EXPECT_SUCCEED helpers::terraform_init "$(dashboard::src_dir)"
}

test::terraform::dashboard::disable_all_widgets () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(dashboard::input_dir)/disable.tfvars" mig >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(dashboard::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(dashboard::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(dashboard::output_dir)/modules.json" \
        "${tfshow}"
    EXPECT_SUCCEED helpers::json_omits \
        "$(dashboard::output_dir)/data.json" \
        "${tfshow}"
}

test::terraform::dashboard::enable_all_widgets () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(dashboard::input_dir)/enable.tfvars" mig >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(dashboard::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(dashboard::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(dashboard::output_dir)/modules.json" \
        "${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(dashboard::output_dir)/data.json" \
        "${tfshow}"
}
