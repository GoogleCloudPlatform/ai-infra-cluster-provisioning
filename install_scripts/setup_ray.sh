#!/bin/bash

# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ray_version=$1
ray_port=$2
gpus_per_vm=$3

# Run Ray under a new user/group.
addgroup ray
adduser --gecos --no-create-home --ingroup ray ray

runuser -u ray -- /opt/conda/bin/pip3 install \
  --no-cache-dir \
  "ray[default]==${ray_version}"

export HEAD_NODE_NAME=""
for machine in $(gcloud compute instances list | grep ${HOSTNAME%-*} | sed 's/\(^\S\+\) .*/\1/');
do
  echo "${machine} -- ${HEAD_NODE_NAME}"
  if [[ "$machine" > "$HEAD_NODE_NAME" ]]; then
    export HEAD_NODE_NAME=$machine
  fi
done
echo "HEAD_NODE_NAME value is $HEAD_NODE_NAME"

if [[  "${HOSTNAME}" == "$HEAD_NODE_NAME" ]]; then
  echo "Starting Ray head node..."
  runuser -u ray -- /opt/conda/bin/ray start \
    --head \
    --port=${ray_port} \
    --num-gpus=${gpus_per_vm}
else
  echo "Starting Ray worker node..."
  runuser -u ray -- /opt/conda/bin/ray start \
    --address=${HEAD_NODE_NAME}:${ray_port} \
    --num-gpus=${gpus_per_vm}
fi

# TODO: The better option is to add users to a Google group, which can then be
# added to the `ray` Posix group. Then, chmod g+w /tmp/ray to give
# group-restricted access to the Ray cluster.
chmod -R a+w /tmp/ray
