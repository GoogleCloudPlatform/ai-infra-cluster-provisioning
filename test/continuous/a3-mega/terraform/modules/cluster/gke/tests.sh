. ./test/helpers.sh

a3-mega::terraform::gke::src_dir () {
    echo "${PWD}/a3-mega/terraform/modules/cluster/gke"
}

a3-mega::terraform::gke::input_dir () {
    echo "${PWD}/test/continuous/a3-mega/terraform/modules/cluster/gke/input"
}

test::a3-mega::terraform::gke () {
    helpers::terraform_init "$(a3-mega::terraform::gke::src_dir)"
}

test::a3-mega::terraform::gke::simple () {
    local -r tfvars=$(mktemp)
    local success=true
    helpers::append_tfvars "$(a3-mega::terraform::gke::input_dir)/simple.tfvars" gke >"${tfvars}"

    ./scripts/entrypoint.sh create a3-mega gke "${tfvars}" || success=false
    ./scripts/entrypoint.sh destroy a3-mega gke "${tfvars}" || success=false

    [ "${success}" = true ]
}
