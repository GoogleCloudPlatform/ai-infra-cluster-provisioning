. ./test/helpers.sh

slurm::src_dir () {
    echo "${PWD}/terraform/modules/cluster/slurm"
}

slurm::input_dir () {
    echo "${PWD}/test/terraform/modules/cluster/slurm/input"
}

slurm::output_dir () {
    echo "${PWD}/test/terraform/modules/cluster/slurm/output"
}

test::terraform::slurm () {
    EXPECT_SUCCEED terraform -chdir="$(slurm::src_dir)" init -reconfigure
}

test::terraform::slurm::fmt () {
    EXPECT_SUCCEED terraform -chdir="$(slurm::src_dir)" fmt -check -recursive
}

test::terraform::slurm::simple_create_modules () {
    tfplan=$(mktemp)
    EXPECT_SUCCEED helpers::terraform_plan \
        "$(slurm::src_dir)" \
        "$(slurm::input_dir)/simple.tfvars" \
        "${tfplan}"
    tfshow=$(mktemp)
    helpers::terraform_show "$(slurm::src_dir)" "${tfplan}" >"${tfshow}"
    EXPECT_SUCCEED helpers::json_contains \
        "$(slurm::output_dir)/modules.json" \
        "${tfshow}"
}
