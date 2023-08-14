. ./test/helpers.sh

a3::terraform::slurm::src_dir () {
    echo "${PWD}/a3/terraform/modules/cluster/slurm"
}

a3::terraform::slurm::input_dir () {
    echo "${PWD}/test/pr/a3/terraform/modules/cluster/slurm/input"
}

a3::terraform::slurm::output_dir () {
    echo "${PWD}/test/pr/a3/terraform/modules/cluster/slurm/output"
}

test::a3::terraform::slurm () {
    EXPECT_SUCCEED helpers::terraform_init "$(a3::terraform::slurm::src_dir)"
}

test::a3::terraform::slurm::defaults () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(a3::terraform::slurm::input_dir)/simple.tfvars" slurm >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(a3::terraform::slurm::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(a3::terraform::slurm::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(a3::terraform::slurm::output_dir)/defaults.json" \
        "${tfshow}"
}

test::a3::terraform::slurm::simple_create_modules () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(a3::terraform::slurm::input_dir)/simple.tfvars" slurm >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(a3::terraform::slurm::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(a3::terraform::slurm::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(a3::terraform::slurm::output_dir)/modules.json" \
        "${tfshow}"
}

test::a3::terraform::slurm::multiple_partitions () {
    local -r tfvars=$(mktemp)
    helpers::append_tfvars "$(a3::terraform::slurm::input_dir)/multiple_partitions.tfvars" slurm >"${tfvars}"

    local -r tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(a3::terraform::slurm::src_dir)" \
        "${tfvars}" \
        "${tfplan}"

    local -r tfshow=$(mktemp)
    helpers::terraform_show "$(a3::terraform::slurm::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(a3::terraform::slurm::output_dir)/multiple_partitions.json" \
        "${tfshow}"
}
