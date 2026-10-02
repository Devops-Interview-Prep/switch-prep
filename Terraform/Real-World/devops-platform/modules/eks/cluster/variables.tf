variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "cluster_version" {
  description = "EKS Kubernetes version."
  type        = string
}

variable "cluster_role_arn" {
  description = "IAM role ARN for the EKS control plane."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the EKS cluster."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs attached to the EKS control plane."
  type        = list(string)
}

variable "kms_key_arn" {
  description = "KMS key ARN used for EKS secrets encryption."
  type        = string
}

variable "enabled_cluster_log_types" {
  description = "EKS control plane log types to enable."
  type        = list(string)
  default = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}

variable "oidc_thumbprint_list" {
  description = "OIDC provider thumbprint list."
  type        = list(string)
  default     = ["9e99a48a9960b14926bb7f3b02e22da0afd29e8f"]
}

variable "cluster_admin_principal_arns" {
  description = "IAM principal ARNs with full EKS cluster-admin access."
  type        = list(string)
  default     = []
}

variable "platform_admin_principal_arns" {
  description = "IAM principal ARNs with EKS admin access."
  type        = list(string)
  default     = []
}

variable "developer_principal_arns" {
  description = "IAM principal ARNs with developer edit access."
  type        = list(string)
  default     = []
}

variable "developer_namespaces" {
  description = "Namespaces where developers get edit access."
  type        = list(string)
  default     = ["default"]
}

variable "viewer_principal_arns" {
  description = "IAM principal ARNs with read-only EKS view access."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
variable "endpoint_private_access" {
  description = "Whether the EKS private API endpoint is enabled."
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Whether the EKS public API endpoint is enabled."
  type        = bool
  default     = false
}

variable "endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to access the public EKS API endpoint."
  type        = list(string)
  default     = []
}