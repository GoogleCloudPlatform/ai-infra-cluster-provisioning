#!/bin/bash

pushd .
mkdir workspace && cd workspace
git clone https://github.com/tensorflow/tensorboard.git && cd tensorboard
docker build -t $REGION-docker.pkg.dev/$PROJECT/$PREFIX:tensorboard .
cd .. && rm -fr tensorboard
popd

docker push $REGION-docker.pkg.dev/$PROJECT/$PREFIX:tensorboard
