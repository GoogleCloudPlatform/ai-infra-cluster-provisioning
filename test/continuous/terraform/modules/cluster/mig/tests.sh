. ./test/helpers.sh

mig::src_dir () {
    echo "${PWD}/terraform/modules/cluster/mig"
}

mig::input_dir () {
    echo "${PWD}/test/continuous/terraform/modules/cluster/mig/input"
}

test::terraform::mig () {
    helpers::terraform_init "$(mig::src_dir)"
}

test::terraform::mig::simple () {
    local -r tfvars=$(mktemp)
    local success=true
    helpers::append_tfvars "$(mig::input_dir)/simple.tfvars" >"${tfvars}"

    ./scripts/entrypoint.sh create mig "${tfvars}" || success=false
    ./scripts/entrypoint.sh destroy mig "${tfvars}" || success=false

    [ "${success}" = true ]
}
