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

  _startup_scripts_template_variables = {
    install_gpu = var.enable_install_gpu
    script      = var.startup_script != null ? replace(var.startup_script, "\n", "\n    ") : ""
  }

  _network_storage_template_variables = {
    filestore_mount_commands = join(
      " && ",
      concat(
        ["true"], // dummy to make join return non-null
        [
          for f in var.filestores
          : "mount -t nfs -o async,hard,rw ${f.remote_mount} ${local._filestore_host_mount}${f.local_mount}"
        ],
        ["true"], // dummy to make join return non-null
      )
    )
    gcsfuse_host_mount = local._gcsfuse_host_mount
    gcsfuse_mount_commands = join(
      " && ",
      concat(
        ["true"], // dummy to make join return non-null
        [
          for g in var.gcsfuses
          : "docker exec gcsfuse gcsfuse --implicit-dirs ${g.remote_mount} ${local._gcsfuse_host_mount}${g.local_mount}"
        ],
        ["true"], // dummy to make join return non-null
      )
    )
    host_mountpoints = join(
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
        ["."], // dummy to make join return non-null and have mkdir succeed
      ),
    )
  }

  _container = {
    cmd   = try(var.container.cmd != null ? var.container.cmd : "", "")
    image = try(var.container.image != null ? var.container.image : "", "")
    run_at_boot = try(
      var.container.run_at_boot != null ? var.container.run_at_boot : true,
      false,
    )
    run_options = {
      custom = try(
        var.container.run_options.custom != null ? (
          var.container.run_options.custom
        ) : [],
        [],
      )
      enable_cloud_logging = try(
        var.container.run_options.enable_cloud_logging != null ? (
          var.container.run_options.enable_cloud_logging
        ) : false,
        false,
      )
      env = try(
        var.container.run_options.env != null ? (
          var.container.run_options.env
        ) : {},
        {}
      )
    }
  }

  _container_template_variables = {
    docker_cmd   = local._container.cmd
    docker_image = local._container.image
    docker_run_options = join(
      " ",
      concat(
        [
          for name, value in local._container.run_options.env
          : "--env ${name}=${value}"
        ],
        local._container.run_options.enable_cloud_logging ? [
          "--log-driver=gcplogs"
        ] : [],
        local._container.run_options.custom,
        [""], // dummy to make join return non-null
      ),
    )
    docker_volume_flags = join(
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
        [""], // dummy to make join return non-null
      ),
    )
    docker_device_flags = join(
      " ",
      [
        "--volume /var/lib/nvidia/lib64:/usr/local/nvidia/lib64",
        "--volume /var/lib/nvidia/bin:/usr/local/nvidia/bin",
        "--device /dev/nvidia-uvm:/dev/nvidia-uvm",
        "--device /dev/nvidiactl:/dev/nvidiactl",
        "$${device_flags}",
      ],
    )
    requirements = join(
      " ",
      concat(
        [
          "aiinfra-network-storage.service",
          "aiinfra-pull-image.service",
          "aiinfra-startup-scripts.service",
        ],
      )
    )
  }

  _userdata_template_variables = merge(
    {
      startup_scripts = {
        file = templatefile(
          "${path.module}/templates/aiinfra_startup_scripts.yaml.template",
          local._startup_scripts_template_variables,
        )
        service = "aiinfra-startup-scripts"
      }
      network_storage = { file = "", service = null, }
      pull_image      = { file = "", service = null, }
      start_container = { file = "", service = null, }
    },
    var.container != null ? {
      network_storage = {
        file = templatefile(
          "${path.module}/templates/aiinfra_network_storage.yaml.template",
          local._network_storage_template_variables,
        )
        service = "aiinfra-network-storage"
      }
      pull_image = {
        file = templatefile(
          "${path.module}/templates/aiinfra_pull_image.yaml.template",
          local._container_template_variables,
        )
        service = "aiinfra-pull-image"
      }
      start_container = {
        file = templatefile(
          "${path.module}/templates/aiinfra_start_container.yaml.template",
          local._container_template_variables,
        )
        service = local._container.run_at_boot ? "aiinfra-start-container" : null
      }
    } : {},
  )
  userdata_template_variables = {
    aiinfra_network_storage = local._userdata_template_variables.network_storage.file
    aiinfra_startup_scripts = local._userdata_template_variables.startup_scripts.file
    aiinfra_pull_image      = local._userdata_template_variables.pull_image.file
    aiinfra_start_container = local._userdata_template_variables.start_container.file
    aiinfra_services = join(
      " ",
      [for k, v in local._userdata_template_variables : v.service if v.service != null],
    )
  }
}

data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = templatefile(
      "${path.module}/templates/userdata.yaml.template",
      local.userdata_template_variables,
    )
    filename = "userdata.yaml"
  }
}
