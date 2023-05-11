. ./test/helpers.sh

network::src_dir () {
    echo "${PWD}/terraform/modules/network"
}

network::input_dir () {
    echo "${PWD}/test/terraform/modules/network/input"
}

network::output_dir () {
    echo "${PWD}/test/terraform/modules/network/output"
}

test::terraform::network () {
    EXPECT_SUCCEED terraform -chdir="$(network::src_dir)" init -reconfigure
}

test::terraform::network::fmt () {
    EXPECT_SUCCEED terraform -chdir="$(network::src_dir)" fmt -check -recursive
}

test::terraform::network::default_network_produces_subnet () {
    tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(network::src_dir)" \
        "$(network::input_dir)/default.tfvars" \
        "${tfplan}"
    tfshow=$(mktemp)
    helpers::terraform_show "$(network::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_STREQ \
        "$(helpers::plan_output "${tfshow}" 'network_id')" \
        'projects/gce-ai-infra/global/networks/default'
    EXPECT_STREQ \
        "$(helpers::plan_output "${tfshow}" 'subnetwork_self_links')" \
        '["https://www.googleapis.com/compute/v1/projects/gce-ai-infra/regions/us-central1/subnetworks/default"]'
}

test::terraform::network::new_network_plans_single_new_vpc () {
    tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(network::src_dir)" \
        "$(network::input_dir)/new_single_nic.tfvars" \
        "${tfplan}"
    tfshow=$(mktemp)
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
    tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(network::src_dir)" \
        "$(network::input_dir)/new_multi_nic.tfvars" \
        "${tfplan}"
    tfshow=$(mktemp)
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
