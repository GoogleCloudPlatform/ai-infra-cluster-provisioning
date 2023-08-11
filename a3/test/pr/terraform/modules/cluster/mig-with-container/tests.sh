. ./test/helpers.sh

mig-with-container::src_dir () {
    echo "${PWD}/terraform/modules/cluster/mig-with-container"
}

mig-with-container::input_dir () {
    echo "${PWD}/test/pr/terraform/modules/cluster/mig-with-container/input"
}

mig-with-container::output_dir () {
    echo "${PWD}/test/pr/terraform/modules/cluster/mig-with-container/output"
}

test::terraform::mig-with-container () {
    EXPECT_SUCCEED helpers::terraform_init "$(mig-with-container::src_dir)"
}

test::terraform::mig-with-container::simple_create_modules () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(mig-with-container::input_dir)/simple.tfvars" mig-with-container >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(mig-with-container::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(mig-with-container::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(mig-with-container::output_dir)/modules.json" \
        "${tfshow}"
}
