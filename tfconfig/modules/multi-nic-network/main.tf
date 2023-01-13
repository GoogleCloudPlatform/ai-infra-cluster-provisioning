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

module "network1" {
  source                = "github.com/GoogleCloudPlatform/hpc-toolkit//modules/network/vpc//?ref=866de32de9c3cf7ea8fa20f377d62aa80a07b8b3"
  network_address_range = "10.0.0.0/16"
  subnetworks = [{
    new_bits      = 8
    subnet_name   = "primary-subnet-one"
    subnet_region = var.region
  }]
  region          = var.region
  deployment_name = var.deployment_name
  project_id      = var.project_id
  network_name    = "${var.deployment_name}-net-1"
}

module "network2" {
  source                = "github.com/GoogleCloudPlatform/hpc-toolkit//modules/network/vpc//?ref=866de32de9c3cf7ea8fa20f377d62aa80a07b8b3"
  network_address_range = "10.1.0.0/16"
  subnetworks = [{
    new_bits      = 8
    subnet_name   = "primary-subnet-two"
    subnet_region = var.region
  }]
  region          = var.region
  deployment_name = var.deployment_name
  project_id      = var.project_id
  network_name    = "${var.deployment_name}-net-2"
}

module "network3" {
  source                = "github.com/GoogleCloudPlatform/hpc-toolkit//modules/network/vpc//?ref=866de32de9c3cf7ea8fa20f377d62aa80a07b8b3"
  network_address_range = "10.2.0.0/16"
  subnetworks = [{
    new_bits      = 8
    subnet_name   = "primary-subnet-three"
    subnet_region = var.region
  }]
  region          = var.region
  deployment_name = var.deployment_name
  project_id      = var.project_id
  network_name    = "${var.deployment_name}-net-3"
}

module "network4" {
  source                = "github.com/GoogleCloudPlatform/hpc-toolkit//modules/network/vpc//?ref=866de32de9c3cf7ea8fa20f377d62aa80a07b8b3"
  network_address_range = "10.3.0.0/16"
  subnetworks = [{
    new_bits      = 8
    subnet_name   = "primary-subnet-four"
    subnet_region = var.region
  }]
  region          = var.region
  deployment_name = var.deployment_name
  project_id      = var.project_id
  network_name    = "${var.deployment_name}-net-4"
}

module "network5" {
  source                = "github.com/GoogleCloudPlatform/hpc-toolkit//modules/network/vpc//?ref=866de32de9c3cf7ea8fa20f377d62aa80a07b8b3"
  network_address_range = "10.4.0.0/16"
  subnetworks = [{
    new_bits      = 8
    subnet_name   = "primary-subnet-five"
    subnet_region = var.region
  }]
  region          = var.region
  deployment_name = var.deployment_name
  project_id      = var.project_id
  network_name    = "${var.deployment_name}-net-5"
}