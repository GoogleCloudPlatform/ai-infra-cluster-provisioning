#!/bin/bash

pushd .
mkdir workspace && cd workspace
git clone https://github.com/tensorflow/tensorboard.git
docker build \
  -f tensorboard/Dockerfile
  -t $REGION-docker.pkg.dev/$PROJECT/$PREFIX/tensorboard 
  tensorboard/
cd .. && rm -fr workspace
popd

docker push $REGION-docker.pkg.dev/$PROJECT/$PREFIX/tensorboard
