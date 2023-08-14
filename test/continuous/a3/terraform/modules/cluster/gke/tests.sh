. ./test/helpers.sh

a3::terraform::gke::src_dir () {
    echo "${PWD}/a3/terraform/modules/cluster/gke"
}

a3::terraform::gke::input_dir () {
    echo "${PWD}/test/continuous/a3/terraform/modules/cluster/gke/input"
}

test::a3::terraform::gke () {
    helpers::terraform_init "$(a3::terraform::gke::src_dir)"
}

test::a3::terraform::gke::simple () {
    local -r tfvars=$(mktemp)
    local success=true
    helpers::append_tfvars "$(a3::terraform::gke::input_dir)/simple.tfvars" gke >"${tfvars}"

    ./scripts/entrypoint.sh a3 create gke "${tfvars}" || success=false
    ./scripts/entrypoint.sh a3 destroy gke "${tfvars}" || success=false

    [ "${success}" = true ]
}
