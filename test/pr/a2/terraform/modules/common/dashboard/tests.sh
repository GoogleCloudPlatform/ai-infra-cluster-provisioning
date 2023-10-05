. ./test/helpers.sh

a2::terraform::dashboard::src_dir () {
    echo "${PWD}/a2/terraform/modules/common/dashboard"
}

a2::terraform::dashboard::input_dir () {
    echo "${PWD}/test/pr/a2/terraform/modules/common/dashboard/input"
}

a2::terraform::dashboard::output_dir () {
    echo "${PWD}/test/pr/a2/terraform/modules/common/dashboard/output"
}

test::a2::terraform::dashboard () {
    EXPECT_SUCCEED helpers::terraform_init "$(a2::terraform::dashboard::src_dir)"
}

test::a2::terraform::dashboard::disable_all_widgets () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(a2::terraform::dashboard::input_dir)/disable.tfvars" mig >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(a2::terraform::dashboard::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(a2::terraform::dashboard::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(a2::terraform::dashboard::output_dir)/modules.json" \
        "${tfshow}"
    EXPECT_SUCCEED helpers::json_omits \
        "$(a2::terraform::dashboard::output_dir)/data.json" \
        "${tfshow}"
}

test::a2::terraform::dashboard::enable_all_widgets () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(a2::terraform::dashboard::input_dir)/enable.tfvars" mig >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(a2::terraform::dashboard::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(a2::terraform::dashboard::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(a2::terraform::dashboard::output_dir)/modules.json" \
        "${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(a2::terraform::dashboard::output_dir)/data.json" \
        "${tfshow}"
}
