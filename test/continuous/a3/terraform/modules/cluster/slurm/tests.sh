. ./test/helpers.sh

slurm::src_dir () {
    echo "${PWD}/a3/terraform/modules/cluster/slurm"
}

slurm::input_dir () {
    echo "${PWD}/test/continuous/a3/terraform/modules/cluster/slurm/input"
}

test::terraform::a3::slurm () {
    helpers::terraform_init "$(slurm::src_dir)"
}

test::terraform::a3::slurm::simple () {
    local -r tfvars=$(mktemp)
    local success=true
    helpers::append_tfvars "$(slurm::input_dir)/simple.tfvars" slurm >"${tfvars}"

    ./scripts/entrypoint.sh create slurm "${tfvars}" || success=false
    ./scripts/entrypoint.sh destroy slurm "${tfvars}" || success=false

    [ "${success}" = true ]
}
