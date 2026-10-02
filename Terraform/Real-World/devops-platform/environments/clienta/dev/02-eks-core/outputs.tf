output "cluster_name" {
  value = module.eks_core.cluster_name
}

output "cluster_arn" {
  value = module.eks_core.cluster_arn
}

output "cluster_endpoint" {
  value = module.eks_core.cluster_endpoint
}

output "cluster_oidc_issuer_url" {
  value = module.eks_core.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  value = module.eks_core.oidc_provider_arn
}

output "eks_kms_key_arn" {
  value = module.eks_core.eks_kms_key_arn
}

output "cluster_iam_role_arn" {
  value = module.eks_core.cluster_iam_role_arn
}

output "node_iam_role_arn" {
  value = module.eks_core.node_iam_role_arn
}

output "system_node_group_name" {
  value = module.eks_core.system_node_group_name
}

output "system_node_group_status" {
  value = module.eks_core.system_node_group_status
}

output "launch_template_id" {
  value = module.eks_core.launch_template_id
}
output "eks_addon_names" {
  value = module.eks_core.eks_addon_names
}

output "eks_addon_arns" {
  value = module.eks_core.eks_addon_arns
}
output "node_iam_role_name" {
  value = module.eks_core.node_iam_role_name
}