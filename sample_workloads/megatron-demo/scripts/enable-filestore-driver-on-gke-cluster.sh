#!/bin/bash

gcloud container clusters update $PREFIX \
  --update-addons=GcpFilestoreCsiDriver=ENABLED \
  --project $PROJECT \
  --region $REGION
