. ./test/helpers.sh

a3::terraform::mig::src_dir () {
    echo "${PWD}/a3/terraform/modules/cluster/mig"
}

a3::terraform::mig::input_dir () {
    echo "${PWD}/test/continuous/a3/terraform/modules/cluster/mig/input"
}

test::a3::terraform::mig () {
    helpers::terraform_init "$(a3::terraform::mig::src_dir)"
}

test::a3::terraform::mig::simple () {
    local -r tfvars=$(mktemp)
    local success=true
    helpers::append_tfvars "$(a3::terraform::mig::input_dir)/simple.tfvars" mig >"${tfvars}"

    ./scripts/entrypoint.sh create a3 mig "${tfvars}" || success=false
    ./scripts/entrypoint.sh destroy a3 mig "${tfvars}" || success=false

    [ "${success}" = true ]
}
