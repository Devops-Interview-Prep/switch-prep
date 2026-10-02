variable "name_prefix" {
  description = "Name prefix for IAM resources."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN."
  type        = string
}

variable "oidc_provider_url" {
  description = "EKS OIDC issuer URL."
  type        = string
}

variable "namespace" {
  description = "Namespace where AWS Load Balancer Controller is installed."
  type        = string
  default     = "kube-system"
}

variable "service_account_name" {
  description = "AWS Load Balancer Controller service account name."
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}