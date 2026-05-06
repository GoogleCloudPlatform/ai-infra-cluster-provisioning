# Base image with JAX and TCPX config

A base image to use with Jax and optimized TCPX config

Image location:
```
us-docker.pkg.dev/$PROJECT_ID/jax-gpu/base-tcpx:0.4.21
```

## Pushing new image
```
gcloud builds submit --config=cloudbuild.yaml \
  --substitutions=_VERSION=0.4.21 --project gce-ai-infra
```