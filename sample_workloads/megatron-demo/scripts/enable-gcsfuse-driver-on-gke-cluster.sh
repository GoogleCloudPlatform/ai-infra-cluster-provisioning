gcloud container clusters update $PREFIX \
    --update-addons GcsFuseCsiDriver=ENABLED \
    --region=$REGION