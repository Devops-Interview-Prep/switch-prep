variable "release_name" {
  description = "ArgoCD Helm release name."
  type        = string
  default     = "argocd"
}

variable "namespace" {
  description = "ArgoCD namespace."
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "ArgoCD Helm chart version."
  type        = string
  default     = "10.1.2"
}

variable "server_service_type" {
  description = "ArgoCD server service type."
  type        = string
  default     = "ClusterIP"
}

variable "server_insecure" {
  description = "Whether to run ArgoCD server in insecure mode behind an external TLS-terminating ingress."
  type        = bool
  default     = false
}

variable "node_selector" {
  description = "Node selector for ArgoCD workloads."
  type        = map(string)
  default     = {}
}

variable "tolerations" {
  description = "Tolerations for ArgoCD workloads."
  type        = list(any)
  default     = []
}