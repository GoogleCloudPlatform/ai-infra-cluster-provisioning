#!/bin/bash

gcloud container clusters get-credentials $TF_VAR_PREFIX \
  --region $TF_VAR_REGION \
  --project $TF_VAR_PROJECT
