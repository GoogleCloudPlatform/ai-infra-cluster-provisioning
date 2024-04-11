. ./test/helpers.sh

a3-mega::terraform::mig::src_dir () {
    echo "${PWD}/a3-mega/terraform/modules/cluster/mig"
}

a3-mega::terraform::mig::input_dir () {
    echo "${PWD}/test/continuous/a3-mega/terraform/modules/cluster/mig/input"
}

test::a3-mega::terraform::mig () {
    helpers::terraform_init "$(a3-mega::terraform::mig::src_dir)"
}

test::a3-mega::terraform::mig::simple () {
    local -r tfvars=$(mktemp)
    local success=true
    helpers::append_tfvars "$(a3-mega::terraform::mig::input_dir)/simple.tfvars" mig >"${tfvars}"

    ./scripts/entrypoint.sh create a3-mega mig "${tfvars}" || success=false
    ./scripts/entrypoint.sh destroy a3-mega mig "${tfvars}" || success=false

    [ "${success}" = true ]
}
