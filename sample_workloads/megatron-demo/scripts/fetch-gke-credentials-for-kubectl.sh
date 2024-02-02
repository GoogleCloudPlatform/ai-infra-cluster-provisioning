#!/bin/bash

gcloud container clusters get-credentials $PREFIX \
  --region $REGION \
  --project $PROJECT
