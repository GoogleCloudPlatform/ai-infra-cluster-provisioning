. ./test/helpers.sh

a3::terraform::slurm::src_dir () {
    echo "${PWD}/a3/terraform/modules/cluster/slurm"
}

a3::terraform::slurm::input_dir () {
    echo "${PWD}/test/continuous/a3/terraform/modules/cluster/slurm/input"
}

test::a3::terraform::slurm () {
    helpers::terraform_init "$(a3::terraform::slurm::src_dir)"
}

test::a3::terraform::slurm::simple () {
    local -r tfvars=$(mktemp)
    local success=true
    helpers::append_tfvars "$(a3::terraform::slurm::input_dir)/simple.tfvars" slurm >"${tfvars}"

    ./scripts/entrypoint.sh create a3 slurm "${tfvars}" || success=false
    ./scripts/entrypoint.sh destroy a3 slurm "${tfvars}" || success=false

    [ "${success}" = true ]
}
