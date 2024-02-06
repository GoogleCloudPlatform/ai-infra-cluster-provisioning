gcloud artifacts repositories create $TF_VAR_PREFIX \
    --repository-format=docker \
    --location=$TF_VAR_REGION