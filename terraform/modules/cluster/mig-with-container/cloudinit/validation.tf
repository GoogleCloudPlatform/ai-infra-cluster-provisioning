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

resource "null_resource" "validation" {

  triggers = {
    always_run = "${timestamp()}"
  }

  lifecycle {
    precondition {
      condition     = var.machine_has_gpu || !var.custom_gpu_drivers
      error_message = "cannot install drivers on a machine with no gpu"
    }
  }
}

