. ./test/helpers.sh

mig::src_dir () {
    echo "${PWD}/terraform/modules/cluster/mig"
}

mig::input_dir () {
    echo "${PWD}/test/pr/terraform/modules/cluster/mig/input"
}

mig::output_dir () {
    echo "${PWD}/test/pr/terraform/modules/cluster/mig/output"
}

test::terraform::mig () {
    EXPECT_SUCCEED helpers::terraform_init "$(mig::src_dir)"
}

test::terraform::mig::simple_create_modules () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(mig::input_dir)/simple.tfvars" mig >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(mig::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(mig::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(mig::output_dir)/modules.json" \
        "${tfshow}"
}

test::terraform::mig::container () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(mig::input_dir)/container.tfvars" >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(mig::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(mig::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(mig::output_dir)/modules.json" \
        "${tfshow}"
}
