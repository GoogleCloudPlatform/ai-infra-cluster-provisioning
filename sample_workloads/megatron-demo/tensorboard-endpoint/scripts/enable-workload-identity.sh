#!/bin/bash

gcloud container clusters update $PREFIX \
    --region=$REGION \
    --workload-pool=$PROJECT.svc.id.goog


gcloud projects add-iam-policy-binding $PROJECT \
    --member "serviceAccount:default@$PROJECT.iam.gserviceaccount.com" \
    --role "ROLE_NAME"
