. ./test/helpers.sh

mig::src_dir () {
    echo "${PWD}/terraform/modules/cluster/mig"
}

mig::input_dir () {
    echo "${PWD}/test/terraform/modules/cluster/mig/input"
}

mig::output_dir () {
    echo "${PWD}/test/terraform/modules/cluster/mig/output"
}

test::terraform::mig () {
    EXPECT_SUCCEED helpers::terraform_init "$(mig::src_dir)"
}

test::terraform::mig::simple_create_modules () {
    tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(mig::src_dir)" \
        "$(mig::input_dir)/simple.tfvars" \
        "${tfplan}"
    tfshow=$(mktemp)
    helpers::terraform_show "$(mig::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(mig::output_dir)/modules.json" \
        "${tfshow}"
}

test::terraform::mig::a2vm_validation_modules () {
    tfplan=$(mktemp)
    EXPECT_FAIL helpers::terraform_plan \
        "$(mig::src_dir)" \
        "$(mig::input_dir)/fail_a2vm.tfvars" \
        "${tfplan}"
}
