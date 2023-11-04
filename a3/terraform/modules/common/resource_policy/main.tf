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

resource "google_compute_resource_policy" "new_placement_policy" {
  provider = google-beta
  count    = var.existing_resource_policy_name != null ? 0 : 1
  name     = var.new_resource_policy_name
  project  = var.project_id
  region   = var.region
  group_placement_policy {
    collocation  = "COLLOCATED"
    max_distance = 2
  }

  lifecycle {
    precondition {
      condition     = var.existing_resource_policy_name == null || var.new_resource_policy_name == null
      error_message = "Both existing_resource_policy_name and new_placement_policy cannot be specified together."
    }
  }
}

data "google_compute_resource_policy" "existing_placement_policy" {
  provider = google-beta
  count    = var.existing_resource_policy_name == null ? 0 : 1
  name     = var.existing_resource_policy_name
  project  = var.project_id
  region   = var.region
  lifecycle {
    precondition {
      condition     = var.existing_resource_policy_name == null || var.new_resource_policy_name == null
      error_message = "Both existing_resource_policy_name and new_placement_policy cannot be specified together."
    }
  }
}