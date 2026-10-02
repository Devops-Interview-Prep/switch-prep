output "node_group_name" {
  description = "EKS managed node group name."
  value       = aws_eks_node_group.this.node_group_name
}

output "node_group_arn" {
  description = "EKS managed node group ARN."
  value       = aws_eks_node_group.this.arn
}

output "node_group_status" {
  description = "EKS managed node group status."
  value       = aws_eks_node_group.this.status
}

output "launch_template_id" {
  description = "Launch template ID used by the node group."
  value       = aws_launch_template.this.id
}

output "launch_template_latest_version" {
  description = "Latest launch template version."
  value       = aws_launch_template.this.latest_version
}