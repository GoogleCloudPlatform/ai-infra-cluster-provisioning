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

  _has_filestores               = try(length(var.filestores) != 0, false)
  _has_gcsfuses                 = try(length(var.gcsfuses) != 0, false)
  _has_network_storage          = local._has_filestores || local._has_gcsfuses
  _has_env_flags                = try(length(keys(var.container.env)) != 0, false)
  _has_options                  = try(length(var.container.options) != 0, false)
  _enable_cloud_logging_options = var.container.enable_cloud_logging ? "--log-driver=gcplogs" : ""

  _base_template_variables = {
    docker_cmd = var.container.cmd != null ? var.container.cmd : ""
    docker_env_flags = local._has_env_flags ? join(
      " ",
      [for name, value in var.container.env : "--env ${name}=${value}"],
    ) : ""
    docker_options = local._has_options ? join(
      " ",
      var.container.options,
      local._enable_cloud_logging_options
    ) : local._enable_cloud_logging_options
    docker_image = var.container.image
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
  _aiinfra_network_storage = templatefile(
    "${path.module}/templates/aiinfra_network_storage.yaml.template",
    local._base_template_variables,
  )
  _aiinfra_pull_image = templatefile(
    "${path.module}/templates/aiinfra_pull_image.yaml.template",
    local._base_template_variables,
  )

  template_variables = merge(
    local._base_template_variables,
    {
      aiinfra_network_storage = local._aiinfra_network_storage,
      aiinfra_pull_image      = local._aiinfra_pull_image
    },
  )
}

data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = templatefile(
      "${path.module}/templates/userdata.yaml.template",
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
      "${path.module}/templates/userdata-gpu.yaml.template",
      local.template_variables,
    )
    filename = "userdata-gpu.yaml"
  }
}
