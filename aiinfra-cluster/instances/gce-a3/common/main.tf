locals {
  startup_script = <<EOT
    DRIVER_VERSION=525.105.17
    sudo apt update
    sudo apt install -y linux-headers-`uname -r` software-properties-common pciutils gcc make dkms
    curl -fSsl -O https://us.download.nvidia.com/tesla/$DRIVER_VERSION/NVIDIA-Linux-x86_64-$DRIVER_VERSION.run
    sudo sh NVIDIA-Linux-x86_64-$DRIVER_VERSION.run --silent
    
    curl https://get.docker.com | sh && sudo systemctl --now enable docker
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
      && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
        sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    
    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker
    sudo nvidia-persistenced --user root
EOT

}

// ---- Instances ---- //
// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_group_manager
resource "google_compute_instance_group_manager" "mig" {
  count              = var.num_migs
  name               = "${var.deployment_name}-mig-${count.index}"
  base_instance_name = "${var.deployment_name}-vm"
  zone               = var.zone
  target_size        = var.num_machines_per_mig
  version {
    instance_template = google_compute_instance_template.instance_template.id
  }
}

// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template
resource "google_compute_instance_template" "instance_template" {
  name_prefix             = "${var.deployment_name}-template-"
  machine_type            = "a3-highgpu-8g"
  metadata_startup_script = local.startup_script
  disk {
    source_image = var.os_image
    disk_type    = "pd-ssd"
    disk_size_gb = 1000
  }
  // NIC 0
  network_interface {
      network    = google_compute_network.networks[0].self_link
      subnetwork = google_compute_subnetwork.subnets[0].self_link
      nic_type   = "GVNIC"
      access_config {} // External IP for SSH
  }
  // NIC 1 to 4
  dynamic "network_interface" {
    for_each = {"1": "", "2": "", "3": "", "4": ""}
    content {
      network    = google_compute_network.networks[tonumber(network_interface.key)].self_link
      subnetwork = google_compute_subnetwork.subnets[tonumber(network_interface.key)].self_link
      nic_type   = "GVNIC"
    }
  }
  scheduling {
    on_host_maintenance = "TERMINATE"
  }
  service_account {
    scopes = ["cloud-platform"]
  }
  lifecycle {
    create_before_destroy = true
  }
}
// -------- //

// ---- Networking ---- //
// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network
resource "google_compute_network" "networks" {
  count                   = 5
  name                    = "${var.deployment_name}-net-${count.index}"
  auto_create_subnetworks = false
}

// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork
resource "google_compute_subnetwork" "subnets" {
  count         = 5
  name          = "${var.deployment_name}-sub-${count.index}"
  ip_cidr_range = "192.168.${count.index}.0/24"
  region        = var.region
  network       = google_compute_network.networks[count.index].self_link
}

// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall
resource "google_compute_firewall" "firewalls" {
  count         = 5
  name          = "${var.deployment_name}-internal-${count.index}"
  network       = google_compute_network.networks[count.index].self_link
  source_ranges = ["192.168.0.0/16"]
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

// Assumes that an external IP is only created for vNIC 0
resource "google_compute_firewall" "firewalls-ping" {
  name          = "${var.deployment_name}-allow-ping-net-0"
  network       = google_compute_network.networks[0].self_link
  source_ranges = ["0.0.0.0/0"]
  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "all_ssh" {
  name    = "${var.deployment_name}-allow-ssh"
  network = google_compute_network.networks[0].self_link
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}
// -------- //
