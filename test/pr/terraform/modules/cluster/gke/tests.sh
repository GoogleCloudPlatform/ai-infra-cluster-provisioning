. ./test/helpers.sh

gke::src_dir () {
    echo "${PWD}/terraform/modules/cluster/gke"
}

gke::input_dir () {
    echo "${PWD}/test/pr/terraform/modules/cluster/gke/input"
}

gke::output_dir () {
    echo "${PWD}/test/pr/terraform/modules/cluster/gke/output"
}

test::terraform::gke () {
    EXPECT_SUCCEED helpers::terraform_init "$(gke::src_dir)"
}

test::terraform::gke::gpu_create_modules () {
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

test::terraform::gke::strict_pp_create_modules () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(gke::input_dir)/gke-strict-pp.tfvars" gke >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(gke::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(gke::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(gke::output_dir)/gke-strict-pp.json" \
        "${tfshow}"
}

test::terraform::gke::incremental_pp_create_modules () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(gke::input_dir)/gke-incremental-pp.tfvars" gke >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(gke::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(gke::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(gke::output_dir)/gke-incremental-pp.json" \
        "${tfshow}"
}
