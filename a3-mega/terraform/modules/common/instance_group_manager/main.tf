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
resource "google_compute_instance_group_manager" "mig" {
  provider = google-beta

  base_instance_name = var.resource_prefix
  name               = var.resource_prefix
  project            = var.project_id
  target_size        = var.target_size
  wait_for_instances = var.wait_for_instances
  zone               = var.zone

  update_policy {
    max_unavailable_fixed = 1
    minimal_action        = "RESTART"
    replacement_method    = "RECREATE" # Instance name will be preserved
    type                  = var.enable_auto_config_apply ? "PROACTIVE" : "OPPORTUNISTIC"
  }

  version {
    instance_template = var.instance_template_id
    name              = "default"
  }

  timeouts {
    create = "30m"
    update = "30m"
  }
}
