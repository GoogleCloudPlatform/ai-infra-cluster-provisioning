export PROJECT=supercomputer-testing
export PREFIX=sufkha-nemo-demo-test
export REGION=us-central1
export ZONE=us-central1-c
export A3_NODE_COUNT=4
export E2_NODE_COUNT=4
export NFS_SIZE="1Ti"

# Expose these variables to Terraform
export TF_VAR_PROJECT=$PROJECT
export TF_VAR_PREFIX=$PREFIX
export TF_VAR_REGION=$REGION
export TF_VAR_ZONE=$ZONE

export TF_VAR_A3_NODE_COUNT=$A3_NODE_COUNT
export TF_VAR_E2_NODE_COUNT=$E2_NODE_COUNT
export TF_VAR_NFS_SIZE=$NFS_SIZE

export A3_GPU_COUNT=$((8*$TF_VAR_A3_NODE_COUNT))
