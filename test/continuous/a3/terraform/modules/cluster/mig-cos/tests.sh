. ./test/helpers.sh

mig-cos::src_dir () {
    echo "${PWD}/a3/terraform/modules/cluster/mig-cos"
}

mig-cos::input_dir () {
    echo "${PWD}/test/continuous/a3/terraform/modules/cluster/mig-cos/input"
}

test::terraform::a3::mig-cos () {
    helpers::terraform_init "$(mig-cos::src_dir)"
}

test::terraform::a3::mig-cos::simple () {
    local -r tfvars=$(mktemp)
    local success=true
    helpers::append_tfvars "$(mig-cos::input_dir)/simple.tfvars" mig-cos >"${tfvars}"

    ./scripts/entrypoint.sh create mig-cos "${tfvars}" || success=false
    ./scripts/entrypoint.sh destroy mig-cos "${tfvars}" || success=false

    [ "${success}" = true ]
}
