variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint."
  type        = string
}

variable "client_name" {
  description = "Client/environment name used in Karpenter NodePool and EC2NodeClass names."
  type        = string
}

variable "namespace" {
  description = "Namespace where Karpenter is installed."
  type        = string
  default     = "kube-system"
}

variable "release_name" {
  description = "Helm release name."
  type        = string
  default     = "karpenter"
}

variable "chart_version" {
  description = "Karpenter Helm chart version."
  type        = string
  default     = "1.13.0"
}

variable "service_account_name" {
  description = "Karpenter service account name."
  type        = string
  default     = "karpenter"
}

variable "controller_role_arn" {
  description = "IAM role ARN mapped to the Karpenter service account through IRSA."
  type        = string
}

variable "node_role_arn" {
  description = "IAM role ARN used by Karpenter-created EC2 nodes."
  type        = string
}

variable "node_role_name" {
  description = "IAM role name used by EC2NodeClass spec.role."
  type        = string
}

variable "ami_alias" {
  description = "Karpenter AMI alias for EC2NodeClass."
  type        = string
  default     = "al2023@latest"
}

variable "replicas" {
  description = "Number of Karpenter controller replicas."
  type        = number
  default     = 2
}

variable "create_node_role_access_entry" {
  description = "Whether to create an EC2_LINUX EKS access entry for the Karpenter node role. Keep false when reusing an existing managed node group role that already has access."
  type        = bool
  default     = false
}
variable "controller_cpu_request" {
  description = "CPU request for Karpenter controller."
  type        = string
  default     = "500m"
}

variable "controller_memory_request" {
  description = "Memory request for Karpenter controller."
  type        = string
  default     = "512Mi"
}

variable "controller_cpu_limit" {
  description = "CPU limit for Karpenter controller."
  type        = string
  default     = "1"
}

variable "controller_memory_limit" {
  description = "Memory limit for Karpenter controller."
  type        = string
  default     = "1Gi"
}