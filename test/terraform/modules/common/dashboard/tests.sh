. ./test/helpers.sh

dashboard::src_dir () {
    echo "${PWD}/terraform/modules/common/dashboard"
}

dashboard::input_dir () {
    echo "${PWD}/test/terraform/modules/common/dashboard/input"
}

dashboard::output_dir () {
    echo "${PWD}/test/terraform/modules/common/dashboard/output"
}

test::terraform::dashboard () {
    EXPECT_SUCCEED terraform -chdir="$(dashboard::src_dir)" init -reconfigure
}

test::terraform::dashboard::disable_all_widgets () {
    tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(dashboard::src_dir)" \
        "$(dashboard::input_dir)/disable.tfvars" \
        "${tfplan}"
    tfshow=$(mktemp)
    helpers::terraform_show "$(dashboard::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(dashboard::output_dir)/modules.json" \
        "${tfshow}"
    EXPECT_SUCCEED helpers::json_omits \
        "$(dashboard::output_dir)/data.json" \
        "${tfshow}"
}

test::terraform::dashboard::enable_all_widgets () {
    tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(dashboard::src_dir)" \
        "$(dashboard::input_dir)/enable.tfvars" \
        "${tfplan}"
    tfshow=$(mktemp)
    helpers::terraform_show "$(dashboard::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(dashboard::output_dir)/modules.json" \
        "${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(dashboard::output_dir)/data.json" \
        "${tfshow}"
}
