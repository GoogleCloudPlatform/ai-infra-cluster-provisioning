. ./test/helpers.sh

gke::src_dir () {
    echo "${PWD}/a3/terraform/modules/cluster/gke"
}

gke::input_dir () {
    echo "${PWD}/test/continuous/a3/terraform/modules/cluster/gke/input"
}

test::terraform::a3::gke () {
    helpers::terraform_init "$(gke::src_dir)"
}

test::terraform::a3::gke::simple () {
    local -r tfvars=$(mktemp)
    local success=true
    helpers::append_tfvars "$(gke::input_dir)/simple.tfvars" gke >"${tfvars}"

    ./scripts/entrypoint.sh create gke "${tfvars}" || success=false
    ./scripts/entrypoint.sh destroy gke "${tfvars}" || success=false

    [ "${success}" = true ]
}
