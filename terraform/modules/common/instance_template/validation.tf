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
  accelerator_optimized = contains(
    ["a2", "a3", "g2"],
    split("-", var.machine_type)[0],
  )
}

resource "null_resource" "validation" {

  triggers = {
    always_run = "${timestamp()}"
  }

  lifecycle {
    precondition {
      condition     = !(local.accelerator_optimized && var.guest_accelerator != null)
      error_message = "a2, a3, and g2 machine families have fixed GPU type and count. Please remove the guest_accelerator block or change the machine type to be one of the n1 family. For more details please check https://cloud.google.com/compute/docs/gpus#a100-40gb"
    }
  }
}
