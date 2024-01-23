module "a3-gke" {
  source = "github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning//a3/terraform/modules/cluster/gke/?ref=megatron"
  # source = "github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning//a3/terraform/modules/cluster/gke-beta/?ref=megatron"
  # source = "../../a3/terraform/modules/cluster/gke-beta/"

  project_id      = "supercomputer-testing"
  resource_prefix = "sufkha-megatron-test"

  gke_version     = "1.27.8-gke.1067000"
  region          = "us-central1"

  node_pools = [
    {
      node_count = 2
      zone       = "us-central1-c"
    },
  ]
}

terraform {
  backend "gcs" {
    bucket = "sufkha-kueue-tf-state"
    prefix = "aiinfra-a3-test"
  }
}
