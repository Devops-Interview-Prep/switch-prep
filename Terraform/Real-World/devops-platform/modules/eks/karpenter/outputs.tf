output "helm_release_name" {
  description = "Karpenter Helm release name."
  value       = helm_release.karpenter.name
}

output "helm_release_namespace" {
  description = "Karpenter Helm release namespace."
  value       = helm_release.karpenter.namespace
}

output "ec2nodeclass_manifest_count" {
  description = "Number of EC2NodeClass manifests applied."
  value       = length(kubectl_manifest.ec2nodeclasses)
}

output "nodepool_manifest_count" {
  description = "Number of NodePool manifests applied."
  value       = length(kubectl_manifest.nodepools)
}