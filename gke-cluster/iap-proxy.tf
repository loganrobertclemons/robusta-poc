#############################################################################
# IAP proxy and instance                                                    #
#############################################################################

locals {
  bastion_instance_startup_script = <<EOF
#! /bin/bash

apt update
apt install -y tinyproxy

# https://serverfault.com/questions/1055510/tinyproxy-error-unable-to-connect-to-the-server-access-denied
grep -qxF 'Allow localhost' /etc/tinyproxy/tinyproxy.conf || echo 'Allow localhost' >> /etc/tinyproxy/tinyproxy.conf
systemctl restart tinyproxy
EOF
}

resource "google_compute_subnetwork" "subnet_iap" {
  count                    = var.gke_cluster_enable_private_endpoint ? 1 : 0
  name                     = format("subnet-iap-%s", var.region)
  ip_cidr_range            = var.iap_proxy_subnet_cidr_range
  network                  = module.vpc.network_id
  private_ip_google_access = "true"
  region                   = var.region
}

resource "google_compute_firewall" "iap_tcp_forwarding" {
  count   = var.gke_cluster_enable_private_endpoint ? 1 : 0
  name    = "allow-ingress-from-iap"
  network = module.vpc.network_id

  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22", "8888"] # 8888 = tinyproxy port
  }

  # https://cloud.google.com/iap/docs/using-tcp-forwarding
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["iap"]
}


resource "google_compute_instance" "iap_proxy" {
  count        = var.gke_cluster_enable_private_endpoint ? 1 : 0
  name         = "iap-proxy"
  machine_type = "e2-micro"
  zone         = var.zone

  tags = ["iap"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  # because we're setting a count on the iap_subnet,
  # we now have to reference it with an index as well
  network_interface {
    network    = module.vpc.network_id
    subnetwork = google_compute_subnetwork.subnet_iap[count.index].name
  }

  metadata_startup_script = local.bastion_instance_startup_script

  depends_on = [
    google_compute_router_nat.vpc_router_nat
  ]
}