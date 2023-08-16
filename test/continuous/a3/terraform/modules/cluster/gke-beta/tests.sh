. ./test/helpers.sh

a3::terraform::gke-beta::src_dir () {
    echo "${PWD}/a3/terraform/modules/cluster/gke-beta"
}

a3::terraform::gke-beta::input_dir () {
    echo "${PWD}/test/continuous/a3/terraform/modules/cluster/gke-beta/input"
}

test::a3::terraform::gke-beta () {
    helpers::terraform_init "$(a3::terraform::gke-beta::src_dir)"
}

test::a3::terraform::gke-beta::simple () {
    local -r tfvars=$(mktemp)
    local success=true
    helpers::append_tfvars "$(a3::terraform::gke-beta::input_dir)/simple.tfvars" gke-beta >"${tfvars}"

    ./scripts/entrypoint.sh create a3 gke-beta "${tfvars}" || success=false
    ./scripts/entrypoint.sh destroy a3 gke-beta "${tfvars}" || success=false

    [ "${success}" = true ]
}
