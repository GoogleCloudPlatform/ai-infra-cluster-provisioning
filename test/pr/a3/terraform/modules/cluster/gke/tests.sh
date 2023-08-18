. ./test/helpers.sh

a3::terraform::gke::src_dir () {
    echo "${PWD}/a3/terraform/modules/cluster/gke"
}

a3::terraform::gke::input_dir () {
    echo "${PWD}/test/pr/a3/terraform/modules/cluster/gke/input"
}

a3::terraform::gke::output_dir () {
    echo "${PWD}/test/pr/a3/terraform/modules/cluster/gke/output"
}

test::a3::terraform::gke () {
    EXPECT_SUCCEED helpers::terraform_init "$(a3::terraform::gke::src_dir)"
}

test::a3::terraform::gke::gpu_create_modules () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(a3::terraform::gke::input_dir)/gke-gpu.tfvars" gke >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(a3::terraform::gke::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(a3::terraform::gke::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(a3::terraform::gke::output_dir)/gke-gpu.json" \
        "${tfshow}"
}

test::a3::terraform::gke::compact_pp_create_modules () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(a3::terraform::gke::input_dir)/gke-compact-pp.tfvars" gke >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(a3::terraform::gke::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(a3::terraform::gke::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(a3::terraform::gke::output_dir)/gke-compact-pp.json" \
        "${tfshow}"
}
