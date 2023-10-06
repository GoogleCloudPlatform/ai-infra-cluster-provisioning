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
  nic = {
    network = {
      id = one(concat(
        data.google_compute_network.nic[*].id,
        resource.google_compute_network.nic[*].id,
      ))
      name = one(concat(
        data.google_compute_network.nic[*].name,
        resource.google_compute_network.nic[*].name,
      ))
      self_link = one(concat(
        data.google_compute_network.nic[*].self_link,
        resource.google_compute_network.nic[*].self_link,
      ))
    }
    subnetwork = {
      name = one(concat(
        data.google_compute_subnetwork.nic[*].name,
        resource.google_compute_subnetwork.nic[*].name,
      ))
      self_link = one(concat(
        data.google_compute_subnetwork.nic[*].self_link,
        resource.google_compute_subnetwork.nic[*].self_link,
      ))
    }
  }
}

// CPU NIC

data "google_compute_network" "nic" {
  count = var.nic_existing != null ? 1 : 0

  name    = var.nic_existing.network_name
  project = var.project_id
}

data "google_compute_subnetwork" "nic" {
  count = var.nic_existing != null ? 1 : 0

  name    = var.nic_existing.subnetwork_name
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "nic" {
  count = var.nic_existing != null ? 0 : 1

  auto_create_subnetworks = false
  mtu                     = 8896
  name                    = var.resource_prefix
  project                 = var.project_id
}

resource "google_compute_subnetwork" "nic" {
  count = var.nic_existing != null ? 0 : 1

  ip_cidr_range = "10.0.0.0/19"
  name          = var.resource_prefix
  network       = google_compute_network.nic[0].self_link
  project       = var.project_id
  region        = var.region
}

resource "google_compute_firewall" "internal-ingress" {
  count = var.nic_existing != null ? 0 : 1

  description   = "internal ingress traffic (icmp/tcp/udp) to machine on nic"
  direction     = "INGRESS"
  name          = "${var.resource_prefix}-internal-ingress"
  network       = google_compute_network.nic[0].self_link
  project       = var.project_id
  source_ranges = ["10.0.0.0/8"]

  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
}

resource "google_compute_firewall" "external-ingress" {
  count = var.nic_existing != null ? 0 : 1

  description   = "external ingress traffic (icmp) to machine on nic"
  direction     = "INGRESS"
  name          = "${var.resource_prefix}-external-ingress"
  network       = google_compute_network.nic[0].self_link
  project       = var.project_id
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "iap-ssh" {
  count = var.nic_existing != null ? 0 : 1

  description   = "identity-aware proxy ssh traffic to machine on nic"
  direction     = "INGRESS"
  name          = "${var.resource_prefix}-iap-ssh"
  network       = google_compute_network.nic[0].self_link
  project       = var.project_id
  source_ranges = ["35.235.240.0/20"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}
