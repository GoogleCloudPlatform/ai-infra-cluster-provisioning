#!/bin/bash

gcloud container node-pools create e2-pool \
    --cluster $PREFIX \
    --region $REGION \
    --node-locations $ZONE \
    --machine-type e2-standard-4 \
    --num-nodes $E2_NODE_COUNT