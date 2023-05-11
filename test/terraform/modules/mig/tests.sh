. ./test/helpers.sh

mig::src_dir () {
    echo "${PWD}/terraform/modules/mig"
}

mig::input_dir () {
    echo "${PWD}/test/terraform/modules/mig/input"
}

mig::output_dir () {
    echo "${PWD}/test/terraform/modules/mig/output"
}

test::terraform::mig () {
    EXPECT_SUCCEED terraform -chdir="$(mig::src_dir)" init -reconfigure
}

test::terraform::mig::fmt () {
    EXPECT_SUCCEED terraform -chdir="$(mig::src_dir)" fmt -check -recursive
}

test::terraform::mig::simple_create_modules () {
    tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(mig::src_dir)" \
        "$(mig::input_dir)/simple.tfvars" \
        "${tfplan}"
    tfshow=$(mktemp)
    helpers::terraform_show "$(mig::src_dir)" "${tfplan}" | jq . >tmp.json #>"${tfshow}"
    #EXPECT_SUCCEED helpers::json_contains \
    #    "$(mig::output_dir)/modules.json" \
    #    "${tfshow}"
}
