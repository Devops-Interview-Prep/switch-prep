output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks_cluster.cluster_name
}

output "cluster_arn" {
  description = "EKS cluster ARN."
  value       = module.eks_cluster.cluster_arn
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint."
  value       = module.eks_cluster.cluster_endpoint
}

output "cluster_oidc_issuer_url" {
  description = "EKS OIDC issuer URL."
  value       = module.eks_cluster.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN."
  value       = module.eks_cluster.oidc_provider_arn
}

output "eks_kms_key_arn" {
  description = "KMS key ARN used for EKS secrets encryption."
  value       = module.eks_kms.key_arn
}

output "cluster_iam_role_arn" {
  description = "EKS cluster IAM role ARN."
  value       = module.eks_roles.cluster_role_arn
}

output "node_iam_role_arn" {
  description = "EKS node IAM role ARN."
  value       = module.eks_roles.node_role_arn
}

output "system_node_group_name" {
  description = "System managed node group name."
  value       = module.system_node_group.node_group_name
}

output "system_node_group_arn" {
  description = "System managed node group ARN."
  value       = module.system_node_group.node_group_arn
}

output "system_node_group_status" {
  description = "System managed node group status."
  value       = module.system_node_group.node_group_status
}

output "launch_template_id" {
  description = "Launch template ID used by the system node group."
  value       = module.system_node_group.launch_template_id
}
output "eks_addon_names" {
  description = "EKS managed add-on names."
  value       = module.eks_addons.addon_names
}

output "eks_addon_arns" {
  description = "EKS managed add-on ARNs."
  value       = module.eks_addons.addon_arns
}
output "node_iam_role_name" {
  description = "EKS node IAM role name."
  value       = module.eks_roles.node_role_name
}