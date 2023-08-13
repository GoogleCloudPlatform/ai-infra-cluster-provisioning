. ./test/helpers.sh

network::src_dir () {
    echo "${PWD}/a3/terraform/modules/common/network"
}

network::input_dir () {
    echo "${PWD}/test/pr/a3/terraform/modules/common/network/input"
}

network::output_dir () {
    echo "${PWD}/test/pr/a3/terraform/modules/common/network/output"
}

test::terraform::a3::network () {
    EXPECT_SUCCEED helpers::terraform_init "$(network::src_dir)"
}

test::terraform::a3::network::existing_network () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(network::input_dir)/existing_network.tfvars" null >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(network::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(network::src_dir)" "${tfplan}" >"${tfshow}"

    EXPECT_SUCCEED helpers::json_contains \
        "$(network::output_dir)/existing_network.json" \
        "${tfshow}"
}

test::terraform::a3::network::new_network () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(network::input_dir)/new_network.tfvars" null >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(network::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(network::src_dir)" "${tfplan}" >"${tfshow}"

    EXPECT_SUCCEED helpers::json_contains \
        "$(network::output_dir)/new_network.json" \
        "${tfshow}"
}
