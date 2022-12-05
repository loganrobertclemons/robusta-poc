#############################################################################
# Outputs                                                                   #
#############################################################################

output "vpc_network_self_link" {
  description = "VPC network self link"
  value       = module.vpc.network_self_link
}

output "vpc_network_name" {
  description = "VPC network name"
  value       = module.vpc.network_name
}

output "vpc_network_id" {
  description = "VPC network ID"
  value       = module.vpc.network_id
}

output "vpc_subnets" {
  description = "VPC subnets"
  value       = module.vpc.subnets
}