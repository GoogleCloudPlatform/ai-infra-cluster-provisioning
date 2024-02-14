#!/bin/bash

docker build \
  -f inverse-proxy/inverse-proxy.Dockerfile \
  -t $REGION-docker.pkg.dev/$PROJECT/$PREFIX/inverse-proxy \
  inverse-proxy/

docker push $REGION-docker.pkg.dev/$PROJECT/$PREFIX/inverse-proxy

