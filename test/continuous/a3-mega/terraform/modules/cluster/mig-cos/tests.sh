. ./test/helpers.sh

a3-mega::terraform::mig-cos::src_dir () {
    echo "${PWD}/a3-mega/terraform/modules/cluster/mig-cos"
}

a3-mega::terraform::mig-cos::input_dir () {
    echo "${PWD}/test/continuous/a3-mega/terraform/modules/cluster/mig-cos/input"
}

test::a3-mega::terraform::mig-cos () {
    helpers::terraform_init "$(a3-mega::terraform::mig-cos::src_dir)"
}

test::a3-mega::terraform::mig-cos::simple () {
    local -r tfvars=$(mktemp)
    local success=true
    helpers::append_tfvars "$(a3-mega::terraform::mig-cos::input_dir)/simple.tfvars" mig-cos >"${tfvars}"

    ./scripts/entrypoint.sh create a3-mega mig-cos "${tfvars}" || success=false
    ./scripts/entrypoint.sh destroy a3-mega mig-cos "${tfvars}" || success=false

    [ "${success}" = true ]
}
