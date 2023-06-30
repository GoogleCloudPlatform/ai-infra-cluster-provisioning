resource "google_compute_instance_group_manager" "mig" {
  provider = google-beta

  base_instance_name = "${var.resource_prefix}-vm"
  name               = "${var.resource_prefix}-mig"
  project            = var.project_id
  target_size        = var.target_size
  wait_for_instances = var.wait_for_instance
  zone               = var.zone

  update_policy {
    max_unavailable_fixed = 1
    minimal_action        = "RESTART"
    type                  = var.enable_auto_config_apply ? "PROACTIVE" : "OPPORTUNISTIC"
    replacement_method    = "RECREATE" # Instance name will be preserved
  }

  version {
    name              = "default"
    instance_template = var.instance_template_id
  }

  timeouts {
    create = "30m"
    update = "30m"
  }
}
