echo "Enabling GCS Fuse driver on GKE cluster"
gcloud container clusters update $PREFIX \
    --update-addons GcsFuseCsiDriver=ENABLED \
    --region=$REGION

echo "Enabling Workload Identity on GKE cluster"
gcloud container clusters update $PREFIX \
    --region=$REGION \
    --workload-pool=$PROJECT.svc.id.goog

echo "Fetching compute engine default service account"
SERVICE_ACCOUNT=$(gcloud iam service-accounts list --filter 'displayName="Compute Engine default service account"' --format "table[No-Heading](Name)")
SERVICE_ACCOUNT=$(basename $SERVICE_ACCOUNT)
echo "Found default service account $SERVICE_ACCOUNT"

echo "Allowing Kuberenetes service account to impersonate IAM service account"
gcloud iam service-accounts add-iam-policy-binding $SERVICE_ACCOUNT \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:$PROJECT.svc.id.goog[default/default]"

echo "Annotating Kuberenetes service account with IAM service account"
kubectl annotate serviceaccount default \
    --namespace default \
    iam.gke.io/gcp-service-account=$SERVICE_ACCOUNT
