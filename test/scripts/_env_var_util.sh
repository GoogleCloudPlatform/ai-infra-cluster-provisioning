. ./test/helpers.sh
. ./usr/_env_var_util.sh

unset_terraform_env_vars () {
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
        LABELS \
        DISK_SIZE_GB \
        DISK_TYPE \
        NETWORK_CONFIG \
        GCS_MOUNT_LIST \
        NFS_FILESHARE_LIST \
        ORCHESTRATOR_TYPE \
        STARTUP_COMMAND \
        ENABLE_OPS_AGENT
}

skip::test::_set_terraform_env_var::fails_when_action_is_not_set () {
    unset_terraform_env_vars
    EXPECT_FAIL _set_terraform_env_var
}
