. ./test/helpers.sh

mig::src_dir () {
    echo "${PWD}/a3/terraform/modules/cluster/mig"
}

mig::input_dir () {
    echo "${PWD}/test/continuous/a3/terraform/modules/cluster/mig/input"
}

test::terraform::a3::mig () {
    helpers::terraform_init "$(mig::src_dir)"
}

test::terraform::a3::mig::simple () {
    local -r tfvars=$(mktemp)
    local success=true
    helpers::append_tfvars "$(mig::input_dir)/simple.tfvars" mig >"${tfvars}"

    ./scripts/entrypoint.sh create mig "${tfvars}" || success=false
    ./scripts/entrypoint.sh destroy mig "${tfvars}" || success=false

    [ "${success}" = true ]
}
