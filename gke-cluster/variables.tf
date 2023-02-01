#############################################################################
# Terraform variables                                                       #
#############################################################################
#############################################################################
# Google Cloud variables                                                    #
#############################################################################
variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP compute region ID"
  default     = "us-central1"
}

variable "zone" {
  type        = string
  description = "GCP compute zone ID"
  default     = "us-central1-a"
}

#############################################################################
# Network                                                                   #
#############################################################################
variable "vpc_name" {
  type        = string
  description = "VPC name"
  default     = "poc-demo-vpc"

  validation {
    condition     = can(regex("[a-z]([-a-z0-9]*[a-z0-9])?", var.vpc_name))
    error_message = "Invalid input, name must be 1-63 characters long and match the regular expression [a-z]([-a-z0-9]*[a-z0-9])?."
  }
}

variable "vpc_routing_mode" {
  type        = string
  description = "VPC routing mode"
  default     = "GLOBAL"

  validation {
    condition     = contains(["GLOBAL", "REGIONAL"], var.vpc_routing_mode)
    error_message = "Invalid input, options: \"GLOBAL\", \"REGIONAL\"."
  }
}

variable "vpc_auto_create_subnetworks" {
  type        = bool
  description = "When true, network is set to 'auto subnet mode' and creates a subnet for each region across 10.128.0.0/9. When false, the user can explicitly connect subnetwork resources."
  default     = false
}

variable "vpc_delete_default_igw_routes" {
  type        = bool
  description = "If set, ensure that all routes within the network specified whose names begin with 'default-route' and with a next hop of 'default-internet-gateway' are deleted."
  default     = false
}

variable "mtu" {
  type        = number
  description = "The network MTU (If set to 0, meaning MTU is unset - defaults to '1460'). Allowed are all values in the inclusive range 1300 to 8896."
  default     = 0
}

#############################################################################
# IAP proxy                                                                 #
#############################################################################
variable "iap_proxy_subnet_cidr_range" {
  type        = string
  description = "The range of internal addresses that are owned by IAP proxy subnetwork."
  default     = "10.50.20.0/24"
}

#############################################################################
# GKE cluster                                                               #
#############################################################################
variable "gke_cluster_name" {
  type        = string
  description = "GKE cluster name."
  default     = "poc-cluster"
}

variable "gke_cluster_regional" {
  type        = bool
  description = "Flag to enable a GKE regional cluster."
  default     = false
}

variable "gke_cluster_version" {
  type        = string
  description = "The Kubernetes version of the masters. If set to 'latest' it will pull latest available version in the selected region."
  default     = "latest"
}

variable "gke_cluster_enable_private_endpoint" {
  type        = bool
  description = "Whether the master's internal IP address is used as the cluster endpoint."
  default     = true
}

variable "gke_cluster_enable_private_nodes" {
  type        = bool
  description = "Whether nodes have internal IP addresses only."
  default     = true
}

variable "gke_cluster_enable_intranode_visibility" {
  type        = bool
  description = "Whether Intra-node visibility is enabled for this cluster. This makes same node pod to pod traffic visible for VPC network."
  default     = false
}

variable "gke_cluster_remove_default_node_pool" {
  type        = bool
  description = "Remove default node pool while setting up the cluster."
  default     = true
}

variable "gke_cluster_master_ipv4_cidr_block" {
  type        = string
  description = "The IP range in CIDR notation to use for the hosted master network."
  default     = "172.16.0.32/28"
  validation {
    condition     = can(cidrhost(var.gke_cluster_master_ipv4_cidr_block, 0))
    error_message = "Must be valid IPv4 CIDR."
  }
}

variable "gke_cluster_master_authorized_networks" {
  type        = list(object({ cidr_block = string, display_name = string }))
  description = "List of master authorized networks. If none are provided, disallow external access (except the cluster node IPs, which GKE automatically whitelists)."
  default     = []
}

variable "gke_cluster_node_pools" {
  type        = list(map(any))
  description = "List of maps containing node pools."
  default = [
    {
      name                      = "poc-default-node-pool"
      machine_type              = "e2-medium"
      node_locations            = "us-central1-b,us-central1-c"
      min_count                 = 1
      max_count                 = 25
      local_ssd_count           = 0
      spot                      = false
      local_ssd_ephemeral_count = 0
      disk_size_gb              = 100
      disk_type                 = "pd-standard"
      image_type                = "COS_CONTAINERD"
      enable_gcfs               = false
      enable_gvnic              = false
      auto_repair               = false
      auto_upgrade              = true
      preemptible               = false
      initial_node_count        = 3
    },
  ]
}
