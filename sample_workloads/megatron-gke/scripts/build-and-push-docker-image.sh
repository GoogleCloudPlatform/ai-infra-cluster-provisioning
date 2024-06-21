#!/bin/bash

docker build \
    -f docker/megatron_example.Dockerfile \
    -t $REGION-docker.pkg.dev/$PROJECT_ID/$USER-test-megatron/pytorch-megatron:23.11-py3 \
    docker/

docker push \
    $REGION-docker.pkg.dev/$PROJECT_ID/$USER-test-megatron/pytorch-megatron:23.11-py3