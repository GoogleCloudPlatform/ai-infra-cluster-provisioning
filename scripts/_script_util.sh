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
# method to expand files to copy.
#
_expand_files_to_copy() {
    fileCopy=""

    # if any volume is mounted at /usr/aiinfra/copy then copy those files
    # to the VM.
    COPY_SRC_PATH=/usr/aiinfra/copy
    if [[  ! -d "$COPY_SRC_PATH" ]]; then
        echo "Directory $COPY_SRC_PATH not found to copy files."
    else
        # default value of copy directory path on the vm is /usr/aiinfra/copy.
        if [[ -z "$COPY_DIR_PATH" ]]; then
            export COPY_DIR_PATH=$COPY_SRC_PATH
        fi

        echo "Files from $COPY_SRC_PATH will be copied to $COPY_DIR_PATH in the VM."
        for filename in $(find $COPY_SRC_PATH -type f)
        do
            if [[ -z "$STARTUP_SCRIPT_PATH" || ${filename,,} != ${STARTUP_SCRIPT_PATH,,} ]]; then
                fn=$(basename ${filename})
                fileCopy+="    }, {\n"
                fileCopy+="    destination = \"$COPY_DIR_PATH/${fn}\"\n"
                fileCopy+="    source      = \"${filename}\"\n"
                fileCopy+="    type        = \"data\"\n" 
            fi
        done
    fi

    sed -i 's|__REPLACE_FILES__|'"$fileCopy"'|' /usr/primary/main.tf
}

#
# method to expand startup script.
#
_expand_startup_script() {
    startupScriptText=""

    # Setup Orchestrator if specified.
    if [[ -z "$ORCHESTRATOR_TYPE" ]]; then
        echo "Orchestrator type is not provided. Skip setting up Orchestrators..."
    elif [[ "${ORCHESTRATOR_TYPE,,}" == "ray" ]]; then
        echo "ORCHESTRATOR_TYPE provided is: $ORCHESTRATOR_TYPE. Setting up Ray..."
        startupScriptText+="    }, {\n"
        startupScriptText+="    type        = \"shell\"\n"
        startupScriptText+="    destination = \"/tmp/setup_ray.sh\"\n"
        startupScriptText+="    source      = \"/usr/setup_ray.sh\"\n"
        startupScriptText+="    args        = \"1.12.1 26379 $GPU_COUNT\"\n"
    else
        echo -e "${RED}ORCHESTRATOR_TYPE $ORCHESTRATOR_TYPE is not supported. Supported Orchestrators are: Ray. Please try again. ${NOC}"
        exit 1
    fi

    # Setup startup script if specified.
    if [[ ! -z "$STARTUP_COMMAND" ]]; then
        echo "Setting up startup command to $STARTUP_COMMAND."
        startupScriptText+="    }, {\n"
        startupScriptText+="    type        = \"shell\"\n"
        startupScriptText+="    destination = \"/tmp/initializestartup.sh\"\n"
        startupScriptText+="    content      = \"$STARTUP_COMMAND\"\n"
    elif [[ ! -z "$STARTUP_SCRIPT_PATH" ]]; then
        if [[ -f "$STARTUP_SCRIPT_PATH" ]]; then
            echo "Setting start up script to $STARTUP_SCRIPT_PATH."
            scName=$(basename ${STARTUP_SCRIPT_PATH})
            startupScriptText+="    }, {\n"
            startupScriptText+="    type        = \"shell\"\n"
            startupScriptText+="    destination = \"/tmp/${scName}\"\n"
            startupScriptText+="    source      = \"$STARTUP_SCRIPT_PATH\"\n"
        else
            echo "The startup script file $STARTUP_SCRIPT_PATH does not exit."
            exit 1
        fi
    fi

    sed -i 's|__REPLACE_STARTUP_SCRIPT__|'"$startupScriptText"'|' /usr/primary/main.tf
}