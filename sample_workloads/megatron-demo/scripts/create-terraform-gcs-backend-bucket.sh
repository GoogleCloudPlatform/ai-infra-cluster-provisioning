#!/bin/bash

gcloud storage buckets create gs://$PREFIX \
  --location $REGION
