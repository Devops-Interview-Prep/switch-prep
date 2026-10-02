variable "role_name" {
  description = "IAM role name."
  type        = string
}

variable "role_purpose" {
  description = "Purpose tag for the IAM role."
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

variable "service_account_subjects" {
  description = "OIDC subject values, for example system:serviceaccount:kube-system:ebs-csi-controller-sa."
  type        = list(string)
}

variable "condition_operator" {
  description = "IAM condition operator. Use StringEquals for exact service account, StringLike for wildcard service accounts."
  type        = string
  default     = "StringEquals"

  validation {
    condition     = contains(["StringEquals", "StringLike"], var.condition_operator)
    error_message = "condition_operator must be StringEquals or StringLike."
  }
}

variable "managed_policy_arns" {
  description = "Managed IAM policy ARNs to attach."
  type        = list(string)
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}