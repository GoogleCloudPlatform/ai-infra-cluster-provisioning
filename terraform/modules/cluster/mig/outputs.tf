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

output "instructions" {
  description = "Instructions for accessing the dashboard"
  value       = try(module.dashboard[0].instructions, "Dashboard not created")
}

output "id" {
  description = "`id` output of the google_compute_instance_template resource created."
  value       = resource.google_compute_instance_template.template.id
}
