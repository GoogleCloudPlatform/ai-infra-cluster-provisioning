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

set -e

source /usr/_env_var_util.sh
source /usr/_terraform_util.sh
source /usr/_storage_util.sh
source /usr/_script_util.sh
source /usr/_debug_util.sh

trap _terraform_cleanup EXIT SIGTERM SIGINT



export GREEN='\e[1;32m'
export RED='\e[0;31m'
export NOC='\e[0m'

echo "================SETTING UP ENVIRONMENT FOR TERRAFORM================"
if [ ! -z "$1" ]; then
    export ACTION=$1
    echo "Setting Action to $ACTION"
fi

_debug_hold
_env_var_util::setup || {
    echo >&2 "failed to set up environment"
    exit 1;
}

echo 'tfvars:'
echo '```terraform'
_env_var_util::print_tfvars \
    $(dbus-uuidgen | head -c6) \
| tee /usr/primary/tf.auto.tfvars
echo '```'

_expand_files_to_copy

gcloud config set project "${PROJECT_ID}" || {
    echo >&2 "failed to set current project to '${PROJECT_ID}'"
    exit 1;
}
_set_terraform_backend
echo "====================================================================="
action_err=0
_perform_terraform_action || action_err=$?
if [ $action_err -eq 0 ]; then
    echo -e "${GREEN}Cluster provisioning successful.. ${NOC}"
else
    echo -e "${RED}Cluster provisioning Failed.. ${NOC}"
fi
