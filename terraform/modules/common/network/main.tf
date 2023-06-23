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

module "default_vpc" {
  source = "github.com/GoogleCloudPlatform/hpc-toolkit//modules/network/pre-existing-vpc//?ref=v1.17.0"
  count  = var.network_config == "default" ? 1 : 0

  project_id = var.project_id
  region     = var.region
}

module "single_new_vpc" {
  source = "github.com/GoogleCloudPlatform/hpc-toolkit//modules/network/vpc//?ref=v1.17.0"
  count  = var.network_config == "new_single_nic" ? 1 : 0

  project_id           = var.project_id
  region               = var.region
  deployment_name      = var.resource_prefix
  network_routing_mode = "REGIONAL"
}

module "multiple_new_vpcs" {
  source = "github.com/GoogleCloudPlatform/hpc-toolkit//modules/network/vpc//?ref=v1.17.0"
  count  = var.network_config == "new_multi_nic" ? 5 : 0

  network_address_range = "10.${count.index}.0.0/16"
  subnetworks = [{
    new_bits      = 8
    subnet_name   = "${var.resource_prefix}-primary-subnet-${count.index}"
    subnet_region = var.region
  }]
  ips_per_nat          = count.index == 0 ? 2 : 0
  region               = var.region
  deployment_name      = var.resource_prefix
  project_id           = var.project_id
  network_name         = "${var.resource_prefix}-net-${count.index}"
  network_routing_mode = "REGIONAL"
}
