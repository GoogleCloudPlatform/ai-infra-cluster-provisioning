. ./test/helpers.sh

gke::src_dir () {
    echo "${PWD}/terraform/modules/cluster/gke"
}

gke::input_dir () {
    echo "${PWD}/test/continuous/terraform/modules/cluster/gke/input"
}

test::terraform::gke () {
    helpers::terraform_init "$(gke::src_dir)"
}

test::terraform::gke::simple () {
    local -r tfvars=$(mktemp)
    local success=true
    helpers::append_tfvars "$(gke::input_dir)/simple.tfvars" >"${tfvars}"

    ./scripts/entrypoint.sh create gke "${tfvars}" || success=false
    ./scripts/entrypoint.sh destroy gke "${tfvars}" || success=false

    [ "${success}" = true ]
}
