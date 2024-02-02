#!/bin/bash

gcloud \
  container clusters update $TF_VAR_PREFIX \
  --update-addons=GcpFilestoreCsiDriver=ENABLED \
  --project $TF_VAR_PROJECT \
  --zone $TF_VAR_ZONE