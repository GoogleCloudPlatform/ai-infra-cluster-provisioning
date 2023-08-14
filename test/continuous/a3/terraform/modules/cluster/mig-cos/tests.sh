. ./test/helpers.sh

a3::terraform::mig-cos::src_dir () {
    echo "${PWD}/a3/terraform/modules/cluster/mig-cos"
}

a3::terraform::mig-cos::input_dir () {
    echo "${PWD}/test/continuous/a3/terraform/modules/cluster/mig-cos/input"
}

test::a3::terraform::mig-cos () {
    helpers::terraform_init "$(a3::terraform::mig-cos::src_dir)"
}

test::a3::terraform::mig-cos::simple () {
    local -r tfvars=$(mktemp)
    local success=true
    helpers::append_tfvars "$(a3::terraform::mig-cos::input_dir)/simple.tfvars" mig-cos >"${tfvars}"

    ./scripts/entrypoint.sh a3 create mig-cos "${tfvars}" || success=false
    ./scripts/entrypoint.sh a3 destroy mig-cos "${tfvars}" || success=false

    [ "${success}" = true ]
}
