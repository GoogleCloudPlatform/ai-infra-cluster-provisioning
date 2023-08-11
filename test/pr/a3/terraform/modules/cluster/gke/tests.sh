. ./test/helpers.sh

gke::src_dir () {
    echo "${PWD}/a3/terraform/modules/cluster/gke"
}

gke::input_dir () {
    echo "${PWD}/test/pr/a3/terraform/modules/cluster/gke/input"
}

gke::output_dir () {
    echo "${PWD}/test/pr/a3/terraform/modules/cluster/gke/output"
}

test::terraform::a3::gke () {
    EXPECT_SUCCEED helpers::terraform_init "$(gke::src_dir)"
}

test::terraform::a3::gke::gpu_create_modules () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(gke::input_dir)/gke-gpu.tfvars" gke >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(gke::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(gke::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(gke::output_dir)/gke-gpu.json" \
        "${tfshow}"
}

test::terraform::gke::compact_pp_create_modules () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(gke::input_dir)/gke-compact-pp.tfvars" gke >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(gke::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(gke::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(gke::output_dir)/gke-compact-pp.json" \
        "${tfshow}"
}
