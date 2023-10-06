. ./test/helpers.sh

a2::terraform::mig::src_dir () {
    echo "${PWD}/a2/terraform/modules/cluster/mig"
}

a2::terraform::mig::input_dir () {
    echo "${PWD}/test/continuous/a2/terraform/modules/cluster/mig/input"
}

test::a2::terraform::mig () {
    helpers::terraform_init "$(a2::terraform::mig::src_dir)"
}

test::a2::terraform::mig::simple () {
    local -r tfvars=$(mktemp)
    local success=true
    helpers::append_tfvars "$(a2::terraform::mig::input_dir)/simple.tfvars" mig >"${tfvars}"

    ./scripts/entrypoint.sh create a2 mig "${tfvars}" || success=false
    ./scripts/entrypoint.sh destroy a2 mig "${tfvars}" || success=false

    [ "${success}" = true ]
}
