output "helm_release_name" {
  description = "ArgoCD Helm release name."
  value       = helm_release.this.name
}

output "helm_release_namespace" {
  description = "ArgoCD namespace."
  value       = helm_release.this.namespace
}

output "helm_release_version" {
  description = "ArgoCD chart version."
  value       = helm_release.this.version
}