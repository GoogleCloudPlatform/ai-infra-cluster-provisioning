variable "PROJECT" {
  type = string
}

variable "REGION" {
  type = string
}

variable "ZONE" {
  type = string
}

variable "PREFIX" {
  type = string
}

variable "A3_NODE_COUNT" {
  type = string
}

module "a3-gke" {
  source = "github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning//a3/terraform/modules/cluster/gke"

  project_id      = var.PROJECT
  resource_prefix = var.PREFIX

  gke_version     = "1.27.8-gke.1067000"
  region          = var.REGION

  ksa = null
  enable_gke_dashboard = false

  node_pools = [
    {
      node_count = var.A3_NODE_COUNT
      zone       = var.ZONE
    },
  ]
}

terraform {
  backend "gcs" {}
}
