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

output "subnetwork_self_links" {
  description = "Primary subnet self-links of all the VPCs"
  value = flatten([
    data.google_compute_subnetwork.default_vpc_subnet[*].self_link,
    module.single_new_vpc[*].subnetwork_self_link,
    module.multiple_new_vpcs[*].subnetwork_self_link,
  ])
}
