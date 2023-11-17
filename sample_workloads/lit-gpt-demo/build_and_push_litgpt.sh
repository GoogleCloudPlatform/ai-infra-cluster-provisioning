#!/usr/bin/env bash

set -euo pipefail

SOME_UUID=$(uuidgen)

LITGPT_PATH=${LITGPT_PATH:="lit-gpt"}
echo $LITGPT_PATH

BASE_IMAGE=${BASE_IMAGE:="$ARTIFACT_REGISTRY/litgpt-base"}
FULL_IMAGE=${FULL_IMAGE:="$ARTIFACT_REGISTRY/litgpt-full"}

# Clone LitGPT and checkout a flash-attn enabled commit
if [ ! -d $LITGPT_PATH ]; then
    git clone https://github.com/Lightning-AI/lit-gpt.git
    cd lit-gpt
    git checkout d5d371417ecb3d3b6c4f30837d8bb7cf2b5310ae
    cd ..
    LITGPT_PATH=lit-gpt
fi

cp Dockerfile $LITGPT_PATH/Dockerfile

cd $LITGPT_PATH
LITGPT_SHA=$(git rev-parse --short HEAD)
cd -

BASE_SHORT_TAG="${LITGPT_SHA}"
BASE_LONG_TAG="${BASE_IMAGE}:${BASE_SHORT_TAG}"

FULL_SHORT_TAG="${BASE_SHORT_TAG}-${SOME_UUID}"
FULL_LONG_TAG="${FULL_IMAGE}:${FULL_SHORT_TAG}"

DOCKER_BUILDKIT=1 docker build -f $LITGPT_PATH/Dockerfile -t $BASE_LONG_TAG $LITGPT_PATH

echo $BASE_LONG_TAG
docker push $BASE_LONG_TAG

DOCKER_BUILDKIT=1 docker build --build-arg LITGPT_BASE=$BASE_LONG_TAG -f LitGPT.Dockerfile -t $FULL_LONG_TAG .

echo $FULL_LONG_TAG
docker push $FULL_LONG_TAG

echo "New tag: $FULL_SHORT_TAG"

