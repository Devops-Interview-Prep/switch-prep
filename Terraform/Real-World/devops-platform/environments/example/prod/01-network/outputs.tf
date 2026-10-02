output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_app_subnet_ids" {
  value = module.network.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  value = module.network.private_db_subnet_ids
}

output "eks_subnet_ids" {
  value = module.network.eks_subnet_ids
}

output "database_subnet_ids" {
  value = module.network.database_subnet_ids
}

output "eks_cluster_security_group_id" {
  value = module.network.eks_cluster_security_group_id
}

output "eks_nodes_security_group_id" {
  value = module.network.eks_nodes_security_group_id
}

output "app_security_group_id" {
  value = module.network.app_security_group_id
}

output "db_security_group_id" {
  value = module.network.db_security_group_id
}
