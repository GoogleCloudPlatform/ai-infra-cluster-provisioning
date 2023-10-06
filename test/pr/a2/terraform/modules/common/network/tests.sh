. ./test/helpers.sh

a2::terraform::network::src_dir () {
    echo "${PWD}/a2/terraform/modules/common/network"
}

a2::terraform::network::input_dir () {
    echo "${PWD}/test/pr/a2/terraform/modules/common/network/input"
}

a2::terraform::network::output_dir () {
    echo "${PWD}/test/pr/a2/terraform/modules/common/network/output"
}

test::a2::terraform::network () {
    EXPECT_SUCCEED helpers::terraform_init "$(a2::terraform::network::src_dir)"
}

test::a2::terraform::network::existing_network () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(a2::terraform::network::input_dir)/existing_network.tfvars" null >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(a2::terraform::network::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(a2::terraform::network::src_dir)" "${tfplan}" >"${tfshow}"

    EXPECT_SUCCEED helpers::json_contains \
        "$(a2::terraform::network::output_dir)/existing_network.json" \
        "${tfshow}"
}

test::a2::terraform::network::new_network () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(a2::terraform::network::input_dir)/new_network.tfvars" null >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(a2::terraform::network::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(a2::terraform::network::src_dir)" "${tfplan}" >"${tfshow}"

    EXPECT_SUCCEED helpers::json_contains \
        "$(a2::terraform::network::output_dir)/new_network.json" \
        "${tfshow}"
}
