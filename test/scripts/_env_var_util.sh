. ./test/helpers.sh
. ./usr/_env_var_util.sh

# print directory containing data with which these tests will compare output
_env_var_util::test::data_dir () {
    echo './test/scripts/_env_var_util_data'
}

# Helper functions

_env_var_util::test::unset_env () {
    unset -v \
        ACTION \
        PROJECT_ID \
        NAME_PREFIX \
        ZONE \
        REGION \
        INSTANCE_COUNT \
        GPU_COUNT \
        VM_TYPE \
        METADATA \
        ACCELERATOR_TYPE \
        IMAGE_FAMILY_NAME \
        IMAGE_NAME \
        IMAGE_PROJECT \
        LABELS \
        DISK_SIZE_GB \
        DISK_TYPE \
        NETWORK_CONFIG \
        GCS_MOUNT_LIST \
        NFS_FILESTORE_LIST \
        ORCHESTRATOR_TYPE \
        STARTUP_COMMAND \
        ENABLE_OPS_AGENT \
        ENABLE_NOTEBOOK \
        GKE_NODE_POOL_COUNT \
        GKE_NODE_COUNT_PER_NODE_POOL \
        GKE_ENABLE_COMPACT_PLACEMENT \
        CUSTOM_NODE_POOL \
        GKE_VERSION \
        SLURM_NODE_COUNT_STATIC \
        SLURM_NODE_COUNT_DYNAMIC_MAX
}

_env_var_util::test::set_required_env () {
    ACTION='create'
    PROJECT_ID='project'
    NAME_PREFIX='test'
    ZONE='us-central1-a'
    unset -v IMAGE_FAMILY_NAME IMAGE_NAME
}

_env_var_util::test::set_defaultable_env () {
    REGION='region'
    GPU_COUNT=3
    VM_TYPE='vm-type'
    METADATA='{key="val"}'
    ACCELERATOR_TYPE='accelerator-type'
    LABELS='{another_key="another_val"}'
    DISK_SIZE_GB=3
    DISK_TYPE='disk-type'
    NETWORK_CONFIG='network'
}

# Test functions

test::_env_var_util::clean::sets_action_to_lowercase () {
    _env_var_util::test::unset_env
    ACTION='ACTION'
    _env_var_util::clean
    EXPECT_STREQ "${ACTION}" 'action'
}

test::_env_var_util::clean::sets_network_config_to_lowercase () {
    _env_var_util::test::unset_env
    NETWORK_CONFIG='NETWORK'
    _env_var_util::clean
    EXPECT_STREQ "${NETWORK_CONFIG}" 'network'
}

test::_env_var_util::clean::sets_orchestrator_type_to_lowercase () {
    _env_var_util::test::unset_env
    ORCHESTRATOR_TYPE='ORCHESTRATOR'
    _env_var_util::clean
    EXPECT_STREQ "${ORCHESTRATOR_TYPE}" 'orchestrator'
}

test::_env_var_util::expect_contains::fails_on_empty_array () {
    declare -ar arr=()
    local -r element=""
    EXPECT_FAIL _env_var_util::expect_contains arr element
}

test::_env_var_util::expect_contains::fails_on_element_missing () {
    declare -ar arr=("apple" "banana")
    local -r element="orange"
    EXPECT_FAIL _env_var_util::expect_contains arr element
}

test::_env_var_util::expect_contains::succeeds_on_element_present () {
    declare -ar arr=("apple" "banana")
    local -r element="apple"
    EXPECT_SUCCEED _env_var_util::expect_contains arr element
}

test::_env_var_util::validate::fails_when_required_is_not_set () {
    declare -ar required_vars=(ACTION PROJECT_ID NAME_PREFIX ZONE)
    for required_var in "${required_vars[@]}"; do
        _env_var_util::test::unset_env
        _env_var_util::test::set_required_env
        unset -v "${required_var}"
        EXPECT_FAIL _env_var_util::validate
    done
}

test::_env_var_util::validate::fails_when_image_and_family_are_both_set () {
    _env_var_util::test::unset_env
    _env_var_util::test::set_required_env
    IMAGE_FAMILY_NAME='image-family'
    IMAGE_NAME='image'
    EXPECT_FAIL _env_var_util::validate
}

test::_env_var_util::validate::fails_when_action_is_set_wrong () {
    _env_var_util::test::unset_env
    _env_var_util::test::set_required_env
    ACTION='wrong'
    EXPECT_FAIL _env_var_util::validate
}

test::_env_var_util::validate::fails_when_network_config_is_set_wrong () {
    _env_var_util::test::unset_env
    _env_var_util::test::set_required_env
    NETWORK_CONFIG='wrong'
    EXPECT_FAIL _env_var_util::validate
}

test::_env_var_util::validate::fails_when_orchestrator_type_is_set_wrong () {
    _env_var_util::test::unset_env
    _env_var_util::test::set_required_env
    ORCHESTRATOR_TYPE='wrong'
    EXPECT_FAIL _env_var_util::validate
}

test::_env_var_util::validate::succeeds_when_required_is_set () {
    _env_var_util::test::unset_env
    _env_var_util::test::set_required_env
    EXPECT_SUCCEED _env_var_util::validate

    _env_var_util::test::unset_env
    _env_var_util::test::set_required_env
    IMAGE_FAMILY_NAME='image-family'
    EXPECT_SUCCEED _env_var_util::validate

    _env_var_util::test::unset_env
    _env_var_util::test::set_required_env
    IMAGE_NAME='image'
    EXPECT_SUCCEED _env_var_util::validate
}

test::_env_var_util::set_defaults::changes_unset_values () {
    _env_var_util::test::unset_env
    _env_var_util::test::set_required_env
    EXPECT_SUCCEED _env_var_util::set_defaults

    EXPECT_STREQ "${REGION}" 'us-central1'
    EXPECT_EQ "${GPU_COUNT}" 2
    EXPECT_STREQ "${VM_TYPE}" 'a2-highgpu-2g'
    EXPECT_STREQ "${METADATA}" '{}'
    EXPECT_STREQ "${ACCELERATOR_TYPE}" 'nvidia-tesla-a100'
    EXPECT_STREQ "${LABELS}" '{}'
    EXPECT_STREQ "${IMAGE_FAMILY_NAME}" 'pytorch-1-12-gpu-debian-10'
    EXPECT_STR_EMPTY "${IMAGE_NAME}"
    EXPECT_STREQ "${IMAGE_PROJECT}" 'ml-images'
    EXPECT_EQ "${DISK_SIZE_GB}" 2000
    EXPECT_STREQ "${DISK_TYPE}" 'pd-ssd'
    EXPECT_STREQ "${NETWORK_CONFIG}" 'default_network'
}

test::_env_var_util::set_defaults::does_not_change_set_values () {
    _env_var_util::test::unset_env
    _env_var_util::test::set_required_env
    _env_var_util::test::set_defaultable_env
    EXPECT_SUCCEED _env_var_util::set_defaults

    EXPECT_STREQ "${REGION}" 'region'
    EXPECT_EQ "${GPU_COUNT}" 3
    EXPECT_STREQ "${VM_TYPE}" 'vm-type'
    EXPECT_STREQ "${METADATA}" '{key="val"}'
    EXPECT_STREQ "${ACCELERATOR_TYPE}" 'accelerator-type'
    EXPECT_STREQ "${LABELS}" '{another_key="another_val"}'
    EXPECT_EQ "${DISK_SIZE_GB}" 3
    EXPECT_STREQ "${DISK_TYPE}" 'disk-type'
    EXPECT_STREQ "${NETWORK_CONFIG}" 'network'

    _env_var_util::test::unset_env
    _env_var_util::test::set_required_env
    IMAGE_FAMILY_NAME='family'
    EXPECT_SUCCEED _env_var_util::set_defaults

    EXPECT_STREQ "${IMAGE_FAMILY_NAME}" 'family'
    EXPECT_STR_EMPTY "${IMAGE_NAME}"
    EXPECT_STREQ "${IMAGE_PROJECT}" 'ml-images'

    _env_var_util::test::unset_env
    _env_var_util::test::set_required_env
    IMAGE_NAME='name'
    EXPECT_SUCCEED _env_var_util::set_defaults

    EXPECT_STR_EMPTY "${IMAGE_FAMILY_NAME}"
    EXPECT_STREQ "${IMAGE_NAME}" 'name'
    EXPECT_STREQ "${IMAGE_PROJECT}" 'ml-images'
}

test::_env_var_util::set_defaults::sets_slurm_values () {
    _env_var_util::test::unset_env
    _env_var_util::test::set_required_env
    ORCHESTRATOR_TYPE='slurm'
    EXPECT_SUCCEED _env_var_util::set_defaults

    EXPECT_STREQ "${IMAGE_FAMILY_NAME}" 'schedmd-v5-slurm-22-05-8-ubuntu-2004-lts'
    EXPECT_STR_EMPTY "${IMAGE_NAME}"
    EXPECT_STREQ "${IMAGE_PROJECT}" 'schedmd-slurm-public'
}

test::_env_var_util::set_defaults::instance_count_defaults_when_not_gke () {
    _env_var_util::test::unset_env
    _env_var_util::test::set_required_env
    EXPECT_SUCCEED _env_var_util::set_defaults
    EXPECT_EQ "${INSTANCE_COUNT}" 1

    _env_var_util::test::unset_env
    _env_var_util::test::set_required_env
    INSTANCE_COUNT=3
    EXPECT_SUCCEED _env_var_util::set_defaults
    EXPECT_EQ "${INSTANCE_COUNT}" 3
}

test::_env_var_util::set_defaults::instance_count_unchanged_when_gke () {
    _env_var_util::test::unset_env
    _env_var_util::test::set_required_env
    ORCHESTRATOR_TYPE='gke'
    EXPECT_SUCCEED _env_var_util::set_defaults
    EXPECT_STR_EMPTY "${INSTANCE_COUNT}"

    _env_var_util::test::unset_env
    _env_var_util::test::set_required_env
    ORCHESTRATOR_TYPE='gke'
    INSTANCE_COUNT=3
    EXPECT_SUCCEED _env_var_util::set_defaults
    EXPECT_EQ "${INSTANCE_COUNT}" 3
}

# idk if it is okay to put service account email address in public repo
# so im not gonna. also i dont think this function really belongs in
# this scope
#test::_env_var_util::get_project_email::gets_project_email () {
#    EXPECT_STREQ \
#        "$(_env_var_util::get_project_email "gce-ai-infra")" \
#        ''
#}

test::_env_var_util::print_tfvars::fails_if_email_not_given () {
    EXPECT_FAIL _env_var_util::print_tfvars
}

test::_env_var_util::print_tfvars::fails_if_uuid_not_given () {
    EXPECT_FAIL _env_var_util::print_tfvars email
}

test::_env_var_util::print_tfvars::succeeds_with_invalid_env () {
    _env_var_util::test::unset_env
    EXPECT_SUCCEED _env_var_util::print_tfvars email uuid >/dev/null
}

test::_env_var_util::print_tfvars::prints_all_required_and_defaultable () {
    _env_var_util::test::unset_env
    _env_var_util::test::set_required_env
    _env_var_util::setup
    EXPECT_SUCCEED diff \
        "$(_env_var_util::test::data_dir)/optionals_unset.tfvars" \
        <(_env_var_util::print_tfvars email uuid)
}

test::_env_var_util::print_tfvars::prints_optionals_when_set () {
    _env_var_util::test::unset_env
    _env_var_util::test::set_required_env
    INSTANCE_COUNT=3
    GCS_MOUNT_LIST='mount'
    NFS_FILESTORE_LIST='filestore'
    ORCHESTRATOR_TYPE='none'
    STARTUP_COMMAND='echo'
    ENABLE_OPS_AGENT='ops'
    ENABLE_NOTEBOOK='note'
    GKE_NODE_POOL_COUNT=3
    GKE_NODE_COUNT_PER_NODE_POOL=3
    CUSTOM_NODE_POOL='custom'
    GKE_VERSION='1.25.7-gke.1000'
    SLURM_NODE_COUNT_STATIC=3
    SLURM_NODE_COUNT_DYNAMIC_MAX=3
    _env_var_util::setup
    EXPECT_SUCCEED diff \
        "$(_env_var_util::test::data_dir)/optionals_set.tfvars" \
        <(_env_var_util::print_tfvars email uuid)
}
