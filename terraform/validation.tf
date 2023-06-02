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

  // Terraform does not provide a way to validate multiple variables in variable validation block.
  // Using this type of validation as per https://github.com/hashicorp/terraform/issues/25609#issuecomment-1057614400
  validate_none_gke = (var.orchestrator_type != "gke" && (var.gke_node_pool_count > 0 || var.gke_node_count_per_node_pool > 0)) ? tobool("Orchestrator type is not GKE. Please remove gke_node_pool_count and gke_node_count_per_node_pool variables.") : true
  validate_custom_node_pool = (length(var.custom_node_pool) > 0 && (var.gke_node_pool_count > 0 || var.gke_node_count_per_node_pool > 0)) ? tobool("Custom node pools are provided. Please do not use gke_node_pool_count and gke_node_count_per_node_pool variables.") : true
  validate_instance_count = (var.orchestrator_type == "gke" && var.instance_count > 0 ) ? tobool("Please do not use instance_count when orchestrator_type is GKE.") : true
  validate_basic_node_pool = (var.orchestrator_type == "gke" && (var.gke_node_pool_count == 0 && var.gke_node_count_per_node_pool > 0)) ? tobool("Please provide gke_node_pool_count for applying gke_node_count_per_node_pool for the GKE basic node pool.") : true

  validate_gke_version = (var.orchestrator_type != "gke" && var.gke_version != null) ? tobool("Orchestrator type is not GKE. Please remove gke_version variable .") : true

  validate_slurm_static = (var.orchestrator_type != "slurm" && var.slurm_node_count_static != 0) ? tobool("slurm_node_count_static must not be set when orchestrator_type is not slurm") : true
  validate_slurm_dynamic_max = (var.orchestrator_type != "slurm" && var.slurm_node_count_dynamic_max != 0) ? tobool("slurm_node_count_dynamic_max must not be set when orchestrator_type is not slurm") : true
}
