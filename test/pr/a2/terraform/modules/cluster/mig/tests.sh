. ./test/helpers.sh

a2::terraform::mig::src_dir () {
    echo "${PWD}/a2/terraform/modules/cluster/mig"
}

a2::terraform::mig::input_dir () {
    echo "${PWD}/test/pr/a2/terraform/modules/cluster/mig/input"
}

a2::terraform::mig::output_dir () {
    echo "${PWD}/test/pr/a2/terraform/modules/cluster/mig/output"
}

test::a2::terraform::mig () {
    EXPECT_SUCCEED helpers::terraform_init "$(a2::terraform::mig::src_dir)"
}

test::a2::terraform::mig::simple_create_modules () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(a2::terraform::mig::input_dir)/simple.tfvars" mig >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(a2::terraform::mig::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(a2::terraform::mig::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(a2::terraform::mig::output_dir)/modules.json" \
        "${tfshow}"
}

test::a2::terraform::mig::multiple_create_modules () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(a2::terraform::mig::input_dir)/multi.tfvars" mig >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(a2::terraform::mig::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(a2::terraform::mig::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(a2::terraform::mig::output_dir)/multimodules.json" \
        "${tfshow}"
}
