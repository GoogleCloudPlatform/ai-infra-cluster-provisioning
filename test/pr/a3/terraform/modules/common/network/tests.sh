. ./test/helpers.sh

a3::terraform::network::src_dir () {
    echo "${PWD}/a3/terraform/modules/common/network"
}

a3::terraform::network::input_dir () {
    echo "${PWD}/test/pr/a3/terraform/modules/common/network/input"
}

a3::terraform::network::output_dir () {
    echo "${PWD}/test/pr/a3/terraform/modules/common/network/output"
}

test::a3::terraform::network () {
    EXPECT_SUCCEED helpers::terraform_init "$(a3::terraform::network::src_dir)"
}

test::a3::terraform::network::existing_network () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(a3::terraform::network::input_dir)/existing_network.tfvars" null >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(a3::terraform::network::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(a3::terraform::network::src_dir)" "${tfplan}" >"${tfshow}"

    EXPECT_SUCCEED helpers::json_contains \
        "$(a3::terraform::network::output_dir)/existing_network.json" \
        "${tfshow}"
}

test::a3::terraform::network::new_network () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(a3::terraform::network::input_dir)/new_network.tfvars" null >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(a3::terraform::network::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(a3::terraform::network::src_dir)" "${tfplan}" >"${tfshow}"

    EXPECT_SUCCEED helpers::json_contains \
        "$(a3::terraform::network::output_dir)/new_network.json" \
        "${tfshow}"
}
