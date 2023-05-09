terraform {
  backend "gcs" {
    bucket  = "aiinfra-terraform-supercomputer-testing"
    prefix  = "production-a3"
  }
}
