. ./test/helpers.sh

a3-mega::terraform::mig::src_dir () {
    echo "${PWD}/a3-mega/terraform/modules/cluster/mig"
}

a3-mega::terraform::mig::input_dir () {
    echo "${PWD}/test/pr/a3-mega/terraform/modules/cluster/mig/input"
}

a3-mega::terraform::mig::output_dir () {
    echo "${PWD}/test/pr/a3-mega/terraform/modules/cluster/mig/output"
}

test::a3-mega::terraform::mig () {
    EXPECT_SUCCEED helpers::terraform_init "$(a3-mega::terraform::mig::src_dir)"
}

test::a3-mega::terraform::mig::simple_create_modules () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(a3-mega::terraform::mig::input_dir)/simple.tfvars" mig >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(a3-mega::terraform::mig::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(a3-mega::terraform::mig::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(a3-mega::terraform::mig::output_dir)/modules.json" \
        "${tfshow}"
}

test::a3-mega::terraform::mig::multiple_create_modules () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(a3-mega::terraform::mig::input_dir)/multi.tfvars" mig >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(a3-mega::terraform::mig::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(a3-mega::terraform::mig::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(a3-mega::terraform::mig::output_dir)/multimodules.json" \
        "${tfshow}"
}

test::a3-mega::terraform::mig::existing_rp_create_modules () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(a3-mega::terraform::mig::input_dir)/existing-rp.tfvars" mig >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(a3-mega::terraform::mig::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(a3-mega::terraform::mig::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(a3-mega::terraform::mig::output_dir)/existing-rp.json" \
        "${tfshow}"
}
