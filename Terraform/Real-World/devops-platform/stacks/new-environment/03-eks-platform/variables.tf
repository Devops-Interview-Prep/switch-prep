variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "client" {
  description = "Client identifier."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "name_prefix" {
  description = "Optional name prefix."
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "cluster_arn" {
  description = "EKS cluster ARN."
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint."
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "EKS cluster OIDC issuer URL."
  type        = string
}

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN."
  type        = string
}

variable "node_iam_role_arn" {
  description = "EKS node IAM role ARN."
  type        = string
}

variable "node_iam_role_name" {
  description = "EKS node IAM role name."
  type        = string
}

variable "karpenter_namespace" {
  description = "Namespace where Karpenter is installed."
  type        = string
  default     = "kube-system"
}

variable "karpenter_release_name" {
  description = "Karpenter Helm release name."
  type        = string
  default     = "karpenter"
}

variable "karpenter_chart_version" {
  description = "Karpenter Helm chart version."
  type        = string
  default     = "1.13.0"
}

variable "karpenter_service_account_name" {
  description = "Karpenter service account name."
  type        = string
  default     = "karpenter"
}

variable "karpenter_ami_alias" {
  description = "Karpenter AMI alias."
  type        = string
  default     = "al2023@latest"
}

variable "karpenter_replicas" {
  description = "Karpenter controller replica count."
  type        = number
  default     = 2
}

variable "create_karpenter_node_role_access_entry" {
  description = "Whether to create EC2_LINUX access entry for Karpenter node role."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
variable "karpenter_controller_cpu_request" {
  description = "CPU request for Karpenter controller."
  type        = string
  default     = "500m"
}

variable "karpenter_controller_memory_request" {
  description = "Memory request for Karpenter controller."
  type        = string
  default     = "512Mi"
}

variable "karpenter_controller_cpu_limit" {
  description = "CPU limit for Karpenter controller."
  type        = string
  default     = "1"
}

variable "karpenter_controller_memory_limit" {
  description = "Memory limit for Karpenter controller."
  type        = string
  default     = "1Gi"
}
variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "aws_load_balancer_controller_namespace" {
  description = "Namespace for AWS Load Balancer Controller."
  type        = string
  default     = "kube-system"
}

variable "aws_load_balancer_controller_release_name" {
  description = "Helm release name for AWS Load Balancer Controller."
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "aws_load_balancer_controller_chart_version" {
  description = "Helm chart version for AWS Load Balancer Controller."
  type        = string
  default     = "1.13.3"
}

variable "aws_load_balancer_controller_service_account_name" {
  description = "Service account name for AWS Load Balancer Controller."
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "aws_load_balancer_controller_replica_count" {
  description = "Replica count for AWS Load Balancer Controller."
  type        = number
  default     = 2
}

variable "aws_load_balancer_controller_node_selector" {
  description = "Node selector for AWS Load Balancer Controller pods."
  type        = map(string)
  default     = {}
}

variable "aws_load_balancer_controller_tolerations" {
  description = "Tolerations for AWS Load Balancer Controller pods."
  type        = list(any)
  default     = []
}
variable "ebs_csi_policy_arn" {
  description = "Optional override for EBS CSI IAM policy ARN."
  type        = string
  default     = null
}

variable "efs_csi_policy_arn" {
  description = "Optional override for EFS CSI IAM policy ARN."
  type        = string
  default     = null
}

variable "ebs_csi_addon_version" {
  description = "Optional EBS CSI add-on version. Null lets EKS choose default."
  type        = string
  default     = null
}

variable "efs_csi_addon_version" {
  description = "Optional EFS CSI add-on version. Null lets EKS choose default."
  type        = string
  default     = null
}

variable "argocd_release_name" {
  description = "ArgoCD Helm release name."
  type        = string
  default     = "argocd"
}

variable "argocd_namespace" {
  description = "ArgoCD namespace."
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "ArgoCD chart version."
  type        = string
  default     = "10.1.2"
}

variable "argocd_server_service_type" {
  description = "ArgoCD server service type."
  type        = string
  default     = "ClusterIP"
}

variable "argocd_server_insecure" {
  description = "Run ArgoCD server in insecure mode behind TLS-terminating ingress."
  type        = bool
  default     = false
}

variable "argocd_node_selector" {
  description = "Node selector for ArgoCD pods."
  type        = map(string)
  default     = {}
}

variable "argocd_tolerations" {
  description = "Tolerations for ArgoCD pods."
  type        = list(any)
  default     = []
}
