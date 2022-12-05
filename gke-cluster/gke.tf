#############################################################################
# GKE                                                                       #
#############################################################################

data "google_compute_zones" "available" {
  region = var.region
  status = "UP"
}

locals {
  gke_cluster_zones              = var.gke_cluster_regional ? data.google_compute_zones.available.names : [var.zone]
  gke_cluster_region             = var.gke_cluster_regional ? var.region : null
  gke_master_authorized_networks = var.gke_cluster_enable_private_endpoint ? [{ display_name = "allow-iap", cidr_block = var.iap_proxy_subnet_cidr_range }] : var.gke_cluster_master_authorized_networks
}

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster"
  version = "~> 23.3"

  project_id         = var.project_id
  name               = var.gke_cluster_name
  regional           = var.gke_cluster_regional
  region             = local.gke_cluster_region
  zones              = local.gke_cluster_zones
  description        = format("%s GKE cluster %s", var.gke_cluster_regional ? "Regional" : "Zonal", var.gke_cluster_name)
  network            = module.vpc.network_name
  subnetwork         = local.subnet_1
  ip_range_pods      = local.secondary_subnet_pods
  ip_range_services  = local.secondary_subnet_services
  kubernetes_version = var.gke_cluster_version

  enable_private_endpoint     = var.gke_cluster_enable_private_endpoint
  enable_private_nodes        = var.gke_cluster_enable_private_nodes
  enable_intranode_visibility = var.gke_cluster_enable_intranode_visibility
  master_ipv4_cidr_block      = var.gke_cluster_master_ipv4_cidr_block
  master_authorized_networks  = local.gke_master_authorized_networks

  http_load_balancing        = true
  network_policy             = false
  horizontal_pod_autoscaling = true
  filestore_csi_driver       = false
  istio                      = false
  cloudrun                   = false
  dns_cache                  = false

  node_pools               = var.gke_cluster_node_pools
  remove_default_node_pool = var.gke_cluster_remove_default_node_pool

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  node_pools_labels = {
    all = {}
  }

  node_pools_metadata = {
    all = {}
  }

  node_pools_taints = {
    all = []
  }

  node_pools_tags = {
    all = []
  }
}
