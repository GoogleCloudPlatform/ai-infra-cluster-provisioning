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

#
# hold the execution if DEBUG_HOLD variable is set.
# till the /tmp/debug_release file is not found
#
_debug_hold() {
    if [[ ! -z "$ACTION" && "${ACTION,,}" == "debug" ]]; then
        echo "Action is set to $ACTION. Waiting for /tmp/debug_release file to be created."
        echo -e "${GREEN} Perform any cction by calling \"/usr/entrypoint.sh create\" or \"/usr/entrypoint.sh destroy\" ${NOC}"
        while [  ! -f /tmp/debug_release ] 
        do
            echo "Waiting 10 seconds for /tmp/debug_release file to be created..."
            sleep 10s
        done
    fi
}