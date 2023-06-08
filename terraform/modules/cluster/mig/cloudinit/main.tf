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
  template_variables = {
    docker_cmd   = try(var.container.cmd, "")
    docker_image = try(var.container.image, "")
    docker_volume_flags = join(
      " ",
      [
        for m in var.filestores[*].local_mount
        : "--volume /var/mnt${m}:${m}:rw"
      ],
    )
    fstab_lines = format("[ %s ]", join(
      ", ",
      [
        for f in var.filestores
        : "[ \"${f.remote_mount}\", \"/var/mnt${f.local_mount}\", \"${f.fs_type}\", \"async,hard,rw\", \"0\", \"2\" ]"
      ],
    ))
    host_mountpoints = join(
      " ",
      [
        for m in var.filestores[*].local_mount
        : "/var/mnt${m}"
      ]
    )
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
