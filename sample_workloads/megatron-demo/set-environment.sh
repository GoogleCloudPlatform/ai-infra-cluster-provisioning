export PROJECT=supercomputer-testing

# GKE cluster name, location, and scale
export PREFIX=sufkha-nemo-demo-test
export REGION=us-central1
export ZONE=us-central1-c
export E2_NODE_COUNT=4
export A3_NODE_COUNT=4

# GKE cluster shared Filestore (i.e. NFS)
# Tier is one of {basic, standard, premium, zonal, or enterprise} 
export NFS_SIZE="1Ti"
export NFS_TIER="enterprise"  

# ---
# Do not edit below this line
export TF_VAR_PROJECT=$PROJECT
export TF_VAR_PREFIX=$PREFIX
export TF_VAR_REGION=$REGION
export TF_VAR_ZONE=$ZONE

export TF_VAR_A3_NODE_COUNT=$A3_NODE_COUNT
export TF_VAR_E2_NODE_COUNT=$E2_NODE_COUNT
export TF_VAR_NFS_SIZE=$NFS_SIZE

export A3_GPU_COUNT=$((8*$TF_VAR_A3_NODE_COUNT))
