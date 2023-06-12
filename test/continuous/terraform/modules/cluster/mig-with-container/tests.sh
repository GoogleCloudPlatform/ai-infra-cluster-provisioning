. ./test/helpers.sh

mig-with-container::src_dir () {
    echo "${PWD}/terraform/modules/cluster/mig-with-container"
}

mig-with-container::input_dir () {
    echo "${PWD}/test/continuous/terraform/modules/cluster/mig-with-container/input"
}

test::terraform::mig-with-container () {
    helpers::terraform_init "$(mig-with-container::src_dir)"
}

test::terraform::mig-with-container::simple () {
    local -r tfvars=$(mktemp)
    local success=true
    helpers::append_tfvars "$(mig-with-container::input_dir)/simple.tfvars" mig-with-container >"${tfvars}"

    ./scripts/entrypoint.sh create mig-with-container "${tfvars}" || success=false
    ./scripts/entrypoint.sh destroy mig-with-container "${tfvars}" || success=false

    [ "${success}" = true ]
}
