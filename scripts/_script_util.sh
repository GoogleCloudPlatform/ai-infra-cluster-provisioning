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
    FILELIST=""

    # if any volume is mounted at /usr/aiinfra/copy then copy those files
    # to the VM.
    COPY_SRC_PATH=/usr/aiinfra/copy
    if [[  ! -d "$COPY_SRC_PATH" ]]; then
        echo "Directory $COPY_SRC_PATH not found to copy files."
    else
        # default value of copy directory path on the vm is /usr/aiinfra/copy.
        if [[ -z "$VM_LOCALFILE_DEST_PATH" ]]; then
            export VM_LOCALFILE_DEST_PATH=$COPY_SRC_PATH
        fi

        echo "Files from $COPY_SRC_PATH will be copied to $VM_LOCALFILE_DEST_PATH in the VM."
        echo "Local file location in the VM: $VM_LOCALFILE_DEST_PATH." >> /usr/info.txt
        FILELIST="$COPY_SRC_PATH:$VM_LOCALFILE_DEST_PATH"
    fi

    # copy example training script based on the image type.
    if [[ ! -z "$IMAGE_FAMILY_NAME" && "$IMAGE_FAMILY_NAME" == *"tf-"* ]] || [[ ! -z "$IMAGE_NAME" && "$IMAGE_NAME" == *"tf-"* ]]; then
        echo "DLVM image used is a TensorFlow image. Copying the TensorFlow example script."
        FILELIST+=",/usr/examples/training_scripts/Tensorflow:/home/jupyter/aiinfra-sample"
    elif [[ ! -z "$IMAGE_FAMILY_NAME" && "$IMAGE_FAMILY_NAME" == *"pytorch-"* ]] || [[ ! -z "$IMAGE_NAME" && "$IMAGE_NAME" == *"pytorch-"* ]]; then
        echo "DLVM image used is a Pytorch image. Copying the pytorch exmple script."
        FILELIST+=",/usr/examples/training_scripts/PyTorch:/home/jupyter/aiinfra-sample"
    else
        echo "IMAGE_FAMILY_NAME=$IMAGE_FAMILY_NAME, IMAGE_NAME=$IMAGE_NAME. These images are neither Tensorflow nor Pytorch Image. Copying all example scripts."
        FILELIST+=",/usr/examples/training_scripts/PyTorch:/home/jupyter/aiinfra-sample,/usr/examples/training_scripts/Tensorflow:/home/jupyter/aiinfra-sample"
    fi

    echo "local_dir_copy_list = \"$FILELIST\"" >> /usr/primary/tf.auto.tfvars
}