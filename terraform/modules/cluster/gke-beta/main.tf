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
}

resource "null_resource" "gke-cluster-command" {
  triggers = {
    cluster_name = "${var.resource_prefix}-gke"
    region       = var.region
  }

  provisioner "local-exec" {
    when        = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
            gcloud container clusters describe ${self.triggers.cluster_name} --region ${self.triggers.region} || 
            gcloud container clusters create ${self.triggers.cluster_name} --region ${self.triggers.region}
        EOT
    on_failure  = fail
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
            gcloud container clusters describe ${self.triggers.cluster_name} --region ${self.triggers.region} &&
            gcloud container clusters delete ${self.triggers.cluster_name} --region ${self.triggers.region} --quiet
        EOT
    on_failure  = fail
  }
}

resource "null_resource" "gke-node-pool-command" {
  for_each = {
    for idx, node_pool in var.node_pools : idx => node_pool
  }

  triggers = {
    cluster_name   = "${var.resource_prefix}-gke"
    region         = var.region
    node_pool_name = "${var.resource_prefix}-nodepool-${each.key}"
  }

  provisioner "local-exec" {
    when        = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
            gcloud container node-pools describe ${self.triggers.node_pool_name} --cluster ${self.triggers.cluster_name} --region ${self.triggers.region} || 
            gcloud container node-pools create ${self.triggers.node_pool_name} --cluster ${self.triggers.cluster_name} --region ${self.triggers.region}
        EOT
    on_failure  = fail
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
            gcloud container node-pools describe ${self.triggers.node_pool_name} --cluster ${self.triggers.cluster_name} --region ${self.triggers.region} &&
            gcloud container node-pools delete ${self.triggers.node_pool_name} --cluster ${self.triggers.cluster_name} --region ${self.triggers.region} --quiet
        EOT
    on_failure  = fail
  }

  depends_on = [null_resource.gke-cluster-command]
}