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
  validate_image_for_ray = (var.orchestrator_type == "ray" && var.instance_image.project != "ml-images" && var.instance_image.project != "deeplearning-platform-release") ? tobool("Orchestrator type RAY is not supported for non-DLVM images. Please remove orchestrator_type variable or use an image from ml-images or deeplearning-platform-release project.") : true
  validate_image_for_enable_notebook = (var.enable_notebook && var.instance_image.project != "ml-images" && var.instance_image.project != "deeplearning-platform-release") ? tobool("Jupyter notebook is not supported for non-DLVM images. Please set enable_notebook variable to false or use an image from ml-images or deeplearning-platform-release project.") : true
}
