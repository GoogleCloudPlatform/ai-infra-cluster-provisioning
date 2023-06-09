/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
*/

locals {
  _filestore_host_mount = "/tmp/cloud/filestore_mnt"
  _gcsfuse_host_mount   = "/tmp/cloud/gcsfuse_mnt"

  _has_filestores      = try(length(var.filestores) != 0, false)
  _has_gcsfuses        = try(length(var.gcsfuses) != 0, false)
  _has_network_storage = local._has_filestores || local._has_gcsfuses

  template_variables = {
    docker_cmd   = try(var.container.cmd, "")
    docker_image = try(var.container.image, "")
    docker_volume_flags = local._has_network_storage ? join(
      " ",
      concat(
        [
          for m in var.filestores[*].local_mount
          : "--volume ${local._filestore_host_mount}${m}:${m}:rw"
        ],
        [
          for m in var.gcsfuses[*].local_mount
          : "--volume ${local._gcsfuse_host_mount}${m}:${m}:rw,rslave"
        ],
      ),
    ) : ""
    filestore_mount_commands = local._has_filestores ? join(
      " && ",
      [
        for f in var.filestores
        : "mount -t nfs -o async,hard,rw ${f.remote_mount} ${local._filestore_host_mount}${f.local_mount}"
      ],
    ) : ""
    gcsfuse_host_mount = local._gcsfuse_host_mount
    gcsfuse_mount_commands = local._has_gcsfuses ? join(
      " && ",
      [
        for g in var.gcsfuses
        : "docker exec gcsfuse gcsfuse --implicit-dirs ${g.remote_mount} ${local._gcsfuse_host_mount}${g.local_mount}"
      ],
    ) : ""
    host_mountpoints = local._has_network_storage ? join(
      " ",
      concat(
        [
          for m in var.filestores[*].local_mount
          : "${local._filestore_host_mount}${m}"
        ],
        [
          for m in var.gcsfuses[*].local_mount
          : "${local._gcsfuse_host_mount}${m}"
        ],
      ),
    ) : ""
  }
}

data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = templatefile(
      "${path.module}/userdata.yaml",
      local.template_variables,
    )
    filename = "userdata.yaml"
  }
}

data "cloudinit_config" "config-gpu" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = templatefile(
      "${path.module}/userdata-gpu.yaml",
      local.template_variables,
    )
    filename = "userdata-gpu.yaml"
  }
}
