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

variable "container" {
  type = object({
    image       = string
    cmd         = string
    run_at_boot = bool
    run_options = object({
      custom               = list(string)
      enable_cloud_logging = bool
      env                  = map(string)
    })
  })

  validation {
    condition = var.container != null ? alltrue(
      [for empty in [null, ""] : var.container.image != empty]
    ) : true
    error_message = "must have non-empty image"
  }
}

variable "enable_install_gpu" {
  type = bool

  validation {
    condition     = var.enable_install_gpu != null
    error_message = "must not be null"
  }
}

variable "filestores" {
  type = list(object({
    local_mount  = string
    remote_mount = string
  }))

  validation {
    condition     = var.filestores != null
    error_message = "must not be null"
  }

  validation {
    condition = alltrue([
      for f in var.filestores
      : alltrue([
        for empty in [null, ""]
        : f.local_mount != empty && f.remote_mount != empty
      ])
    ])
    error_message = "local_mount and remote_mount must not be null"
  }
}

variable "gcsfuses" {
  type = list(object({
    local_mount  = string
    remote_mount = string
  }))

  validation {
    condition     = var.gcsfuses != null
    error_message = "must not be null"
  }

  validation {
    condition = try(
      alltrue([
        for g in var.gcsfuses
        : alltrue([
          for empty in [null, ""]
          : g.local_mount != empty && g.remote_mount != empty
        ])
      ]),
      true
    )
    error_message = "local_mount and remote_mount must not be null"
  }
}

variable "startup_script" {
  type = string
}
