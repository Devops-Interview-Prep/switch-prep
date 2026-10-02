variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "namespace" {
  description = "Namespace where AWS Load Balancer Controller is installed."
  type        = string
  default     = "kube-system"
}

variable "release_name" {
  description = "Helm release name."
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "chart_version" {
  description = "AWS Load Balancer Controller Helm chart version."
  type        = string
  default     = "1.13.3"
}

variable "service_account_name" {
  description = "Service account name."
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "service_account_role_arn" {
  description = "IAM role ARN for service account."
  type        = string
}

variable "replica_count" {
  description = "Controller replica count."
  type        = number
  default     = 2
}

variable "node_selector" {
  description = "Node selector for controller pods."
  type        = map(string)
  default     = {}
}

variable "tolerations" {
  description = "Tolerations for controller pods."
  type        = list(any)
  default     = []
}