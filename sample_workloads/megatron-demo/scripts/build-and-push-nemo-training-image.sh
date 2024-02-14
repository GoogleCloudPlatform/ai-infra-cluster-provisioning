#!/bin/bash

docker build \
  -f nemo-example/docker/nemo_example.Dockerfile \
  -t $REGION-docker.pkg.dev/$PROJECT/$PREFIX/nemofw-training:23.05-py3 \
  nemo-example/docker

docker push $REGION-docker.pkg.dev/$PROJECT/$PREFIX/nemofw-training:23.05-py3