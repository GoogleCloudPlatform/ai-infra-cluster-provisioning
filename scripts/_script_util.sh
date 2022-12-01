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
    if [[ ! -z "$COPY_DIR_PATH" ]]; then
        if [[ -d "$COPY_DIR_PATH" ]]; then
            echo "Files from $COPY_DIR_PATH will be copied to the VM."
            for filename in $(find $COPY_DIR_PATH -type f)
            do
                if [[ -z "$STARTUP_SCRIPT_PATH" || ${filename,,} != ${STARTUP_SCRIPT_PATH,,} ]]; then
                    fn=$(basename ${filename})
                    fileCopy+="    }, {\n"
                    fileCopy+="    destination = \"/tmp/${fn}\"\n"
                    fileCopy+="    source      = \"${filename}\"\n"
                    fileCopy+="    type        = \"data\"\n" 
                fi
            done
        else
            echo "Directory $COPY_DIR_PATH not found to copy files."
            exit 1
        fi
    fi
    
    sed -i 's|__REPLACE_FILES__|'"$fileCopy"'|' /usr/primary/main.tf
}

#
# method to expand startup script.
#
_expand_startup_script() {
    startupScriptText=""

    # Setup Ray if specified.
    if [[ ! -z "$SETUP_RAY" && "$SETUP_RAY" == "yes" ]]; then
        echo "Setting up ray."
        startupScriptText+="    }, {\n"
        startupScriptText+="    type        = \"shell\"\n"
        startupScriptText+="    destination = \"/tmp/setup_ray.sh\"\n"
        startupScriptText+="    source      = \"/usr/setup_ray.sh\"\n"
        startupScriptText+="    args        = \"1.12.1 26379 $GPU_COUNT\"\n"
    fi

    # Setup startup script if specified.
    if [[ ! -z "$STARTUP_SCRIPT" ]]; then
        echo "Setting up startup script to $STARTUP_SCRIPT."
        startupScriptText+="    }, {\n"
        startupScriptText+="    type        = \"shell\"\n"
        startupScriptText+="    destination = \"/tmp/initializestartup.sh\"\n"
        startupScriptText+="    content      = \"$STARTUP_SCRIPT\"\n"
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