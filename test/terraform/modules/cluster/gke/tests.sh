. ./test/helpers.sh

gke::src_dir () {
    echo "${PWD}/terraform/modules/cluster/gke"
}

gke::input_dir () {
    echo "${PWD}/test/terraform/modules/cluster/gke/input"
}

gke::output_dir () {
    echo "${PWD}/test/terraform/modules/cluster/gke/output"
}

test::terraform::gke () {
    EXPECT_SUCCEED terraform -chdir="$(gke::src_dir)" init -reconfigure
}

test::terraform::gke::fmt () {
    EXPECT_SUCCEED terraform -chdir="$(gke::src_dir)" fmt -check -recursive
}

test::terraform::gke::gke_gpu_create_modules () {
    tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(gke::src_dir)" \
        "$(gke::input_dir)/gke-gpu.tfvars" \
        "${tfplan}"
    tfshow=$(mktemp)
    helpers::terraform_show "$(gke::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(gke::output_dir)/gke-gpu.json" \
        "${tfshow}"
}

test::terraform::gke::gke_nongpu_create_modules () {
    tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(gke::src_dir)" \
        "$(gke::input_dir)/gke-nongpu.tfvars" \
        "${tfplan}"
    tfshow=$(mktemp)
    helpers::terraform_show "$(gke::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(gke::output_dir)/gke-nongpu.json" \
        "${tfshow}"
}
