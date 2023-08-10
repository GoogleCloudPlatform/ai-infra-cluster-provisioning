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

resource "google_compute_resource_policy" "placement_policy" {
  provider = google-beta

  name    = var.resource_policy_name
  project = var.project_id
  region  = var.region
  group_placement_policy {
    collocation  = "COLLOCATED"
    max_distance = 2
    vm_count     = var.vm_count
  }
}