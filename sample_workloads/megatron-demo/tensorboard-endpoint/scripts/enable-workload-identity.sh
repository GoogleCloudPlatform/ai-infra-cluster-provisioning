#!/bin/bash

gcloud container clusters update $PREFIX \
    --region=$REGION \
    --workload-pool=$PROJECT.svc.id.goog

DEFAULT_SERVICEACCOUNT=$(gcloud iam service-accounts list --format="table[no-heading](name)" --filter "displayName='Compute Engine default service account'")
echo "Found default service account $DEFAULT_SERVICEACCOUNT"

DEFAULT_SERVICEACCOUNT=$(basename $DEFAULT_SERVICEACCOUNT)

echo "Adding role to service account $DEFAULT_SERVICEACCOUNT"
gcloud iam service-accounts add-iam-policy-binding $DEFAULT_SERVICEACCOUNT \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:$PROJECT.svc.id.goog[default/default]"

kubectl annotate serviceaccount default \
    --namespace default --overwrite \
    iam.gke.io/gcp-service-account=$DEFAULT_SERVICEACCOUNT
