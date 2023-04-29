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
  gke_master_version = var.gke_version != null ? var.gke_version : data.google_container_engine_versions.gkeversion.latest_master_version
  kubernetes_service_account_name = "default"
  kubernetes_service_account_namespace = "default"
}

data "google_client_config" "current" {}

data "google_container_engine_versions" "gkeversion" {
  location = var.region
  project  = var.project
}

# Definition of the private GKE cluster.
resource "google_container_cluster" "gke-cluster" {
  provider = google-beta

  project  = var.project
  name     = var.name
  location = var.region
  node_locations = var.node_locations

  # We need to explicitly manage the node pool to enable features such as
  # auto-upgrade and auto-scaling, but we can't create a cluster with no node
  # pool defined. So we create the smallest possible default  node pool and
  # immediately delete it. This is a best-practice suggested in the Terraform
  # documentation for the container_cluster resource.
  remove_default_node_pool = true
  initial_node_count = 1
  min_master_version = local.gke_master_version

  network    = var.network_self_link
  subnetwork = var.subnetwork_self_link

  # Enable the master authorized networks only when VPCSC is enabled.
  # Note: the existence of the "master_authorized_networks_config" block enables
  # the master authorized networks even if it's empty. Here the block is dynamic
  # that it only exists when VPCSC is enabled.
  master_authorized_networks_config {
  }

  # Security Note: Basic Auth Disabled, no client certificate accepted.
  # The only way to manage the master is via OpenID tokens (aka gcloud).
  # (requirement H5; go/gke-cluster-pattern#req1.1.7)
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Enable shielded nodes to meet go/gke-cluster-pattern#req1.1.5
  enable_shielded_nodes = true

  cluster_autoscaling {
    autoscaling_profile = "OPTIMIZE_UTILIZATION"
    # The name of this attribute is very misleading, it controls node
    # autoprovisioning (NAP), not autoscaling.
    enabled = false
  }

  network_policy {
    # Enabling NetworkPolicy for clusters with DatapathProvider=ADVANCED_DATAPATH
    # is not allowed. Dataplane V2 will take care of network policy enforcement
    # instead.
    enabled = false
    # GKE Dataplane V2 support. This must be set to PROVIDER_UNSPECIFIED in
    # order to let the datapath_provider take effect.
    # https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/issues/656#issuecomment-720398658
    provider = "PROVIDER_UNSPECIFIED"
  }

  # This change will also enable the metadata server on nodes.
  # go/gke-cluster-pattern#req4.1.1#req1.1.5 (parts of, vTPM is another section)
  workload_identity_config {
    workload_pool = "${var.project}.svc.id.goog"
  }

  authenticator_groups_config {
    # Contact safer-gcp to get your group whitelisted for access.
    # Beta feaure: don't depend on it for breakglass access.
    security_group = "gke-security-groups@google.com"
  }

  # GKE Dataplane V2 support
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#datapath_provider
  datapath_provider = var.enable_dataplane_v2 ? "ADVANCED_DATAPATH" : "DATAPATH_PROVIDER_UNSPECIFIED"

  # regular release is required for all 1.24+ features.
  release_channel {
    channel = "UNSPECIFIED"
  }

  addons_config {
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
  }

  lifecycle {
    # Ignore all changes to the default node pool. It's being removed
    # after creation anyway.
    ignore_changes = [
      node_config
    ]
  }

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  timeouts {
    create = "120m"
    update = "120m"
  }
}

# We define explict node pools, so that it can be modified without
# having to destroy the entire cluster.
resource "google_container_node_pool" "gke-node-pools" {
  provider = google-beta

  for_each = {
    for node_pool in var.node_pools : node_pool.name => node_pool
  }

  project            = var.project
  name               = each.value.name
  cluster            = google_container_cluster.gke-cluster.id
  node_locations     = [each.value.zone]
  node_count         = each.value.node_count

  upgrade_settings {
    max_surge       = 0
    max_unavailable = 1
  }

  management {
    auto_repair  = true
    # disabling auto_upgrade to stop automatic upgrade during customer workload execution.
    auto_upgrade = false
  }

  node_config {
    # Requirement H4: custom service account.
    # go/gke-cluster-pattern#req1.1.6
    service_account = var.node_service_account

    machine_type = each.value.machine_type

    # Forcing the use of the Container-optimized image, as it is the only
    # image with the proper logging deamon installed.
    #
    # cos images use Shielded VMs since v1.13.6-gke.0.
    # https://cloud.google.com/kubernetes-engine/docs/how-to/node-images
    #
    # We use COS_CONTAINERD to be compatible with (optional) gVisor.
    # https://cloud.google.com/kubernetes-engine/docs/how-to/sandbox-pods
    #
    # go/gke-cluster-pattern#req3.1.1
    # go/gke-cluster-pattern#req1.1.5
    image_type = "COS_CONTAINERD"

    disk_size_gb = var.disk_size_gb
    disk_type    = var.disk_type

    # Enable features on shielded nodes for go/gke-cluster-pattern#req1.1.5.
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    dynamic "guest_accelerator" {
      for_each = each.value.guest_accelerator_count > 0 ? [1] : []
      content {
        count = each.value.guest_accelerator_count
        type  = each.value.guest_accelerator_type
      }
    }

    gvnic {
      enabled = true
    }

    # Implied by Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Implied by workload identity.
    metadata = {
      "disable-legacy-endpoints" = "true"
    }

    oauth_scopes = var.scopes
  }

  dynamic "placement_policy" {
      for_each = each.value.enable_compact_placement ? [1] : []
      content {
        type = "COMPACT"
      }
    }

  lifecycle {
    ignore_changes = [
      node_config[0].labels,
      node_config[0].taint,
    ]
  }
  timeouts {
    create = "60m"
    update = "60m"
  }
}


# For container logs to show up under Cloud Logging and GKE metrics to show up
# on Cloud Monitoring console, some project level roles are needed for the
# node_service_account
resource "google_project_iam_member" "node_service_account_logWriter" {
  project = var.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${var.node_service_account}"
}

resource "google_project_iam_member" "node_service_account_metricWriter" {
  project = var.project
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${var.node_service_account}"
}

resource "google_project_iam_member" "node_service_account_monitoringViewer" {
  project = var.project
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${var.node_service_account}"
}