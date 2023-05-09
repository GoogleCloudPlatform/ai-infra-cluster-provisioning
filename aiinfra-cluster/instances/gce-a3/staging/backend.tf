terraform {
  backend "gcs" {
    bucket  = "aiinfra-terraform-supercomputer-testing"
    prefix  = "staging-a3"
  }
}
