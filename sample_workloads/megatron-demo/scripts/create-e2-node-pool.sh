#!/bin/bash

gcloud container node-pools create e2-pool \
    --cluster $TF_VAR_PREFIX \
    --region $TF_VAR_REGION \
    --node-locations $TF_VAR_ZONE \
    --machine-type e2-standard-4 \
    --num-nodes $TF_VAR_E2_NODE_COUNT