output "helm_release_name" {
  description = "Helm release name."
  value       = helm_release.this.name
}

output "helm_release_namespace" {
  description = "Helm release namespace."
  value       = helm_release.this.namespace
}

output "helm_release_version" {
  description = "Helm chart version."
  value       = helm_release.this.version
}