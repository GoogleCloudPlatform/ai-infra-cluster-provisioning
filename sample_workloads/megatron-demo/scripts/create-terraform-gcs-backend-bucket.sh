#!/bin/bash

gcloud storage buckets create gs://$TF_VAR_PREFIX \
  --location $TF_VAR_REGION
