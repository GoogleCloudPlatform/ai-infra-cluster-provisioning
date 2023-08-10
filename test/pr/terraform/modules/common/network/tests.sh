. ./test/helpers.sh

network::src_dir () {
    echo "${PWD}/terraform/modules/common/network"
}

network::input_dir () {
    echo "${PWD}/test/pr/terraform/modules/common/network/input"
}

network::output_dir () {
    echo "${PWD}/test/pr/terraform/modules/common/network/output"
}

test::terraform::network () {
    EXPECT_SUCCEED helpers::terraform_init "$(network::src_dir)"
}

test::terraform::network::default_network_produces_subnet () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(network::input_dir)/default.tfvars" mig >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(network::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(network::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_STREQ \
        "$(helpers::plan_output "${tfshow}" 'network_id')" \
        "projects/${runner_arg_project_id}/global/networks/default"
    EXPECT_STREQ \
        "$(helpers::plan_output "${tfshow}" 'subnetwork_self_links')" \
        "[\"https://www.googleapis.com/compute/v1/projects/${runner_arg_project_id}/regions/us-central1/subnetworks/default\"]"
}

test::terraform::network::new_network_plans_single_new_vpc () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(network::input_dir)/new_single_nic.tfvars" mig >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(network::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(network::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(network::output_dir)/new_single_nic.json" \
        "${tfshow}"
    EXPECT_STREQ \
        "$(helpers::plan_output "${tfshow}" 'network_id')" \
        'null'
    EXPECT_STREQ \
        "$(helpers::plan_output "${tfshow}" 'subnetwork_self_links')" \
        'null'
}

test::terraform::network::multi_nic_network_plans_multiple_new_vpcs () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(network::input_dir)/new_multi_nic.tfvars" mig >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(network::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(network::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(network::output_dir)/new_multi_nic.json" \
        "${tfshow}"
    EXPECT_STREQ \
        "$(helpers::plan_output "${tfshow}" 'network_id')" \
        'null'
    EXPECT_STREQ \
        "$(helpers::plan_output "${tfshow}" 'subnetwork_self_links')" \
        'null'
}

test::terraform::network::default_multi_nic_network_plans_multiple_new_vpcs () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(network::input_dir)/default_multi_nic.tfvars" mig >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(network::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(network::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(network::output_dir)/default_multi_nic.json" \
        "${tfshow}"
    EXPECT_STREQ \
        "$(helpers::plan_output "${tfshow}" 'network_id')" \
        "projects/${runner_arg_project_id}/global/networks/default"
}
