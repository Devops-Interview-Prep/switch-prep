output "karpenter_controller_role_arn" {
  description = "Karpenter controller IAM role ARN."
  value       = module.karpenter_iam.controller_role_arn
}

output "karpenter_controller_policy_arn" {
  description = "Karpenter controller IAM policy ARN."
  value       = module.karpenter_iam.controller_policy_arn
}

output "karpenter_helm_release_name" {
  description = "Karpenter Helm release name."
  value       = module.karpenter.helm_release_name
}

output "karpenter_helm_release_namespace" {
  description = "Karpenter Helm release namespace."
  value       = module.karpenter.helm_release_namespace
}

output "karpenter_ec2nodeclass_manifest_count" {
  description = "Number of EC2NodeClass manifests applied."
  value       = module.karpenter.ec2nodeclass_manifest_count
}

output "karpenter_nodepool_manifest_count" {
  description = "Number of NodePool manifests applied."
  value       = module.karpenter.nodepool_manifest_count
}
output "aws_load_balancer_controller_role_arn" {
  description = "AWS Load Balancer Controller IAM role ARN."
  value       = module.aws_load_balancer_controller_iam.role_arn
}

output "aws_load_balancer_controller_policy_arn" {
  description = "AWS Load Balancer Controller IAM policy ARN."
  value       = module.aws_load_balancer_controller_iam.policy_arn
}

output "aws_load_balancer_controller_helm_release_name" {
  description = "AWS Load Balancer Controller Helm release name."
  value       = module.aws_load_balancer_controller.helm_release_name
}

output "aws_load_balancer_controller_helm_release_namespace" {
  description = "AWS Load Balancer Controller Helm namespace."
  value       = module.aws_load_balancer_controller.helm_release_namespace
}
output "ebs_csi_role_arn" {
  description = "EBS CSI driver IAM role ARN."
  value       = module.ebs_csi_irsa.role_arn
}

output "efs_csi_role_arn" {
  description = "EFS CSI driver IAM role ARN."
  value       = module.efs_csi_irsa.role_arn
}

output "storage_addon_names" {
  description = "Storage EKS add-on names."
  value       = module.storage_addons.addon_names
}

output "argocd_helm_release_name" {
  description = "ArgoCD Helm release name."
  value       = module.argocd.helm_release_name
}

output "argocd_helm_release_namespace" {
  description = "ArgoCD namespace."
  value       = module.argocd.helm_release_namespace
}