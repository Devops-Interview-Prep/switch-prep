output "eks_cluster_security_group_id" {
  description = "Security group ID for the EKS cluster control plane."
  value       = aws_security_group.eks_cluster.id
}

output "eks_nodes_security_group_id" {
  description = "Security group ID for EKS worker nodes."
  value       = aws_security_group.eks_nodes.id
}

output "app_security_group_id" {
  description = "Security group ID for application workloads."
  value       = aws_security_group.app.id
}

output "db_security_group_id" {
  description = "Security group ID for database resources."
  value       = aws_security_group.db.id
}