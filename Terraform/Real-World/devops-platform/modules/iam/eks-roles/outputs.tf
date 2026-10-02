output "cluster_role_name" {
  description = "EKS cluster IAM role name."
  value       = aws_iam_role.cluster.name
}

output "cluster_role_arn" {
  description = "EKS cluster IAM role ARN."
  value       = aws_iam_role.cluster.arn
}

output "node_role_name" {
  description = "EKS node IAM role name."
  value       = aws_iam_role.nodes.name
}

output "node_role_arn" {
  description = "EKS node IAM role ARN."
  value       = aws_iam_role.nodes.arn
}
