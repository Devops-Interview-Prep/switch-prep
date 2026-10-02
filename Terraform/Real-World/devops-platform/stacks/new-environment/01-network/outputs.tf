output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "vpc_arn" {
  description = "VPC ARN."
  value       = module.vpc.vpc_arn
}

output "vpc_cidr_block" {
  description = "VPC CIDR block."
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.subnets.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "Private application subnet IDs."
  value       = module.subnets.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "Private database subnet IDs."
  value       = module.subnets.private_db_subnet_ids
}

output "eks_subnet_ids" {
  description = "Subnet IDs intended for EKS nodes."
  value       = module.subnets.private_app_subnet_ids
}

output "database_subnet_ids" {
  description = "Subnet IDs intended for RDS databases."
  value       = module.subnets.private_db_subnet_ids
}

output "internet_gateway_id" {
  description = "Internet Gateway ID."
  value       = module.routing.internet_gateway_id
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs."
  value       = module.routing.nat_gateway_ids
}

output "nat_gateway_mode" {
  description = "NAT Gateway mode."
  value       = module.routing.nat_gateway_mode
}

output "public_route_table_id" {
  description = "Public route table ID."
  value       = module.routing.public_route_table_id
}

output "private_app_route_table_ids" {
  description = "Private application route table IDs."
  value       = module.routing.private_app_route_table_ids
}

output "private_db_route_table_ids" {
  description = "Private database route table IDs."
  value       = module.routing.private_db_route_table_ids
}

output "eks_cluster_security_group_id" {
  description = "Security group ID for EKS cluster control plane."
  value       = module.security_groups.eks_cluster_security_group_id
}

output "eks_nodes_security_group_id" {
  description = "Security group ID for EKS worker nodes."
  value       = module.security_groups.eks_nodes_security_group_id
}

output "app_security_group_id" {
  description = "Application security group ID."
  value       = module.security_groups.app_security_group_id
}

output "db_security_group_id" {
  description = "Database security group ID."
  value       = module.security_groups.db_security_group_id
}
