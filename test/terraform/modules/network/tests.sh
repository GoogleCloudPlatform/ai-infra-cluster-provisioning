. ./test/helpers.sh

network::src_dir () {
    echo "${PWD}/aiinfra-cluster/modules/aiinfra-network"
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

test::terraform::network::plans_nothing_for_default_network () {
    tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(network::src_dir)" \
        "$(network::input_dir)/default_network.tfvars" \
        "${tfplan}"
    tfshow=$(mktemp)
    helpers::terraform_show "$(network::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_STREQ \
        "$(helpers::plan_output "${tfshow}" 'network_name')" \
        'default'
    EXPECT_STREQ \
        "$(helpers::plan_output "${tfshow}" 'network_interfaces')" \
        '[]'
    EXPECT_STREQ \
        "$(helpers::plan_output "${tfshow}" 'network_self_link')" \
        'https://www.googleapis.com/compute/v1/projects/gce-ai-infra/global/networks/default'
    EXPECT_STREQ \
        "$(helpers::plan_output "${tfshow}" 'subnetwork_self_link')" \
        'https://www.googleapis.com/compute/v1/projects/gce-ai-infra/regions/us-central1/subnetworks/default'
}
test::terraform::network::plans_nothing_for_default_network () {
    tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(network::src_dir)" \
        "$(network::input_dir)/default_network.tfvars" \
        "${tfplan}"
    tfshow=$(mktemp)
    helpers::terraform_show "$(network::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_STREQ \
        "$(helpers::plan_output "${tfshow}" 'network_name')" \
        'default'
    EXPECT_STREQ \
        "$(helpers::plan_output "${tfshow}" 'network_interfaces')" \
        '[]'
    EXPECT_STREQ \
        "$(helpers::plan_output "${tfshow}" 'network_self_link')" \
        'https://www.googleapis.com/compute/v1/projects/gce-ai-infra/global/networks/default'
    EXPECT_STREQ \
        "$(helpers::plan_output "${tfshow}" 'subnetwork_self_link')" \
        'https://www.googleapis.com/compute/v1/projects/gce-ai-infra/regions/us-central1/subnetworks/default'
}
