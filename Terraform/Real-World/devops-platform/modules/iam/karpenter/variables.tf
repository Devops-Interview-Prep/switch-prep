variable "name_prefix" {
  description = "Name prefix for Karpenter IAM resources."
  type        = string
}

variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "cluster_arn" {
  description = "EKS cluster ARN."
  type        = string
}

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN."
  type        = string
}

variable "oidc_provider_url" {
  description = "EKS OIDC provider issuer URL."
  type        = string
}

variable "namespace" {
  description = "Karpenter namespace."
  type        = string
  default     = "kube-system"
}

variable "service_account_name" {
  description = "Karpenter service account name."
  type        = string
  default     = "karpenter"
}

variable "node_role_arn" {
  description = "IAM role ARN used by Karpenter-created nodes."
  type        = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}