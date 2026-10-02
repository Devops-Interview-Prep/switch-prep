output "karpenter_controller_role_arn" {
  value = module.eks_platform.karpenter_controller_role_arn
}

output "karpenter_controller_policy_arn" {
  value = module.eks_platform.karpenter_controller_policy_arn
}

output "karpenter_helm_release_name" {
  value = module.eks_platform.karpenter_helm_release_name
}

output "karpenter_helm_release_namespace" {
  value = module.eks_platform.karpenter_helm_release_namespace
}

output "karpenter_ec2nodeclass_manifest_count" {
  value = module.eks_platform.karpenter_ec2nodeclass_manifest_count
}

output "karpenter_nodepool_manifest_count" {
  value = module.eks_platform.karpenter_nodepool_manifest_count
}

output "aws_load_balancer_controller_role_arn" {
  value = module.eks_platform.aws_load_balancer_controller_role_arn
}

output "aws_load_balancer_controller_policy_arn" {
  value = module.eks_platform.aws_load_balancer_controller_policy_arn
}

output "aws_load_balancer_controller_helm_release_name" {
  value = module.eks_platform.aws_load_balancer_controller_helm_release_name
}

output "aws_load_balancer_controller_helm_release_namespace" {
  value = module.eks_platform.aws_load_balancer_controller_helm_release_namespace
}
output "ebs_csi_role_arn" {
  value = module.eks_platform.ebs_csi_role_arn
}

output "efs_csi_role_arn" {
  value = module.eks_platform.efs_csi_role_arn
}

output "storage_addon_names" {
  value = module.eks_platform.storage_addon_names
}

output "argocd_helm_release_name" {
  value = module.eks_platform.argocd_helm_release_name
}

output "argocd_helm_release_namespace" {
  value = module.eks_platform.argocd_helm_release_namespace
}