#!/bin/bash

gcloud storage buckets create gs://$USER-test-megatron \
  --location=$REGION \
  --project=$PROJECT_ID

gcloud artifacts repositories create $USER-test-megatron \
  --repository-format=docker \
  --location=$REGION \
  --project=$PROJECT_ID

gcloud auth configure-docker $REGION-docker.pkg.dev