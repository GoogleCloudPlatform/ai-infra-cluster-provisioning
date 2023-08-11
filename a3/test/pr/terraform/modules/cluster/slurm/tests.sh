. ./test/helpers.sh

slurm::src_dir () {
    echo "${PWD}/terraform/modules/cluster/slurm"
}

slurm::input_dir () {
    echo "${PWD}/test/pr/terraform/modules/cluster/slurm/input"
}

slurm::output_dir () {
    echo "${PWD}/test/pr/terraform/modules/cluster/slurm/output"
}

test::terraform::slurm () {
    EXPECT_SUCCEED helpers::terraform_init "$(slurm::src_dir)"
}

test::terraform::slurm::defaults () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(slurm::input_dir)/simple.tfvars" slurm >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(slurm::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(slurm::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(slurm::output_dir)/defaults.json" \
        "${tfshow}"
}

test::terraform::slurm::simple_create_modules () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(slurm::input_dir)/simple.tfvars" slurm >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(slurm::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(slurm::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(slurm::output_dir)/modules.json" \
        "${tfshow}"
}

test::terraform::slurm::multiple_partitions () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(slurm::input_dir)/multiple_partitions.tfvars" slurm >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(slurm::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(slurm::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(slurm::output_dir)/multiple_partitions.json" \
        "${tfshow}"
}
