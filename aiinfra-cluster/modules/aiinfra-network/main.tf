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
  trimmed_net_config = lower(trimspace(var.network_config))
  primary_network    = coalesce(one(module.new_vpc), try(module.multinic_vpc[0], null), one(module.default_vpc))
  empty_access_config = {
    nat_ip                 = null,
    public_ptr_domain_name = null,
    network_tier           = null
  }
}

module "default_vpc" {
  count      = local.trimmed_net_config != "new_network" ? 1 : 0
  source     = "github.com/GoogleCloudPlatform/hpc-toolkit//modules/network/pre-existing-vpc//?ref=v1.17.0"
  project_id = var.project_id
  region     = var.region
}

module "new_vpc" {
  count           = local.trimmed_net_config == "new_network" ? 1 : 0
  source          = "github.com/GoogleCloudPlatform/hpc-toolkit//modules/network/vpc//?ref=v1.17.0"
  project_id      = var.project_id
  region          = var.region
  deployment_name = var.resource_prefix
}

module "multinic_vpc" {
  source                = "github.com/GoogleCloudPlatform/hpc-toolkit//modules/network/vpc//?ref=v1.17.0"
  count                 = local.trimmed_net_config == "multi_nic_network" ? var.nic_count : 0
  network_address_range = "10.${count.index}.0.0/16"
  subnetworks = [{
    new_bits      = 8
    subnet_name   = "${var.resource_prefix}-primary-subnet-${count.index}"
    subnet_region = var.region
  }]
  ips_per_nat     = count.index == 0 ? 2 : 0
  region          = var.region
  deployment_name = var.resource_prefix
  project_id      = var.project_id
  network_name    = "${var.resource_prefix}-net-${count.index}"
}
