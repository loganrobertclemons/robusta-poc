#############################################################################
# VPC                                                                       #
#############################################################################

locals {
  subnet_1                   = format("%s-subnet-1", var.vpc_name)
  secondary_subnet_pods      = format("%s-secondary-subnet-pods", local.subnet_1)
  secondary_subnet_services  = format("%s-secondary-subnet-services", local.subnet_1)
}

module "vpc" {
  source     = "terraform-google-modules/network/google"
  version    = "~> 6.0"
  project_id = var.project_id

  network_name                           = var.vpc_name
  description                            = format("%s managed by Terraform", var.vpc_name)
  routing_mode                           = var.vpc_routing_mode
  auto_create_subnetworks                = var.vpc_auto_create_subnetworks
  delete_default_internet_gateway_routes = var.vpc_delete_default_igw_routes
  mtu                                    = var.mtu

  subnets = [
    {
      subnet_name           = local.subnet_1
      subnet_ip             = "10.50.10.0/24"
      subnet_region         = "us-central1"
      subnet_private_access = "true"
      subnet_flow_logs      = "true"
    },
  ]

  secondary_ranges = {
    tostring(local.subnet_1) = [
      {
        range_name    = local.secondary_subnet_pods
        ip_cidr_range = "192.168.64.0/20"
      },
      {
        range_name    = local.secondary_subnet_services
        ip_cidr_range = "192.168.128.0/24"
      },
    ]
  }
}

#############################################################################
# Network Firewall rules                                                    #
#############################################################################

resource "google_compute_firewall" "lb_health_check" {
  name        = "allow-health-check"
  network     = module.vpc.network_name
  description = format("VPC %s - Allow health checks from GCP LBs", var.vpc_name)
  direction   = "INGRESS"

  allow {
    protocol = "tcp"
  }
  # https://cloud.google.com/load-balancing/docs/health-check-concepts#ip-ranges
  source_ranges = [
    "35.191.0.0/16",  # Global external HTTP(S) load balancer 
    "130.211.0.0/22", # Global external HTTP(S) load balancer (classic)
  ]
}

#############################################################################
# Routers                                                                   #
# - Only created when a GKE cluster with private nodes is requested         #               
#############################################################################

# https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters
resource "google_compute_router" "vpc_router" {
  count   = var.gke_cluster_enable_private_nodes ? 1 : 0
  name    = format("%s-router", var.vpc_name)
  region  = var.region
  network = module.vpc.network_id
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat
resource "google_compute_router_nat" "vpc_router_nat" {
  count                              = var.gke_cluster_enable_private_nodes ? 1 : 0
  name                               = format("%s-router-nat", var.vpc_name)
  router                             = google_compute_router.vpc_router[count.index].name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = false
    filter = "ERRORS_ONLY"
  }
}