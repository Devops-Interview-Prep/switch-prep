variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "remote_state_bucket" {
  description = "S3 bucket where Terraform remote states are stored."
  type        = string
}

variable "network_state_key" {
  description = "S3 key for the 01-network Terraform state."
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
  description = "Optional EKS cluster name."
  type        = string
  default     = null
}

variable "cluster_version" {
  description = "EKS Kubernetes version."
  type        = string
}

variable "enabled_cluster_log_types" {
  description = "EKS control plane logs to enable."
  type        = list(string)
  default = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}

variable "attach_cni_policy_to_node_role" {
  description = "Attach AmazonEKS_CNI_Policy to node role for bootstrap."
  type        = bool
  default     = true
}

variable "cluster_admin_principal_arns" {
  description = "IAM principal ARNs with full cluster-admin access."
  type        = list(string)
  default     = []
}

variable "platform_admin_principal_arns" {
  description = "IAM principal ARNs with EKS admin access."
  type        = list(string)
  default     = []
}

variable "developer_principal_arns" {
  description = "IAM principal ARNs with namespace-scoped developer edit access."
  type        = list(string)
  default     = []
}

variable "developer_namespaces" {
  description = "Namespaces where developer principals receive edit access."
  type        = list(string)
  default     = ["default"]
}

variable "viewer_principal_arns" {
  description = "IAM principal ARNs with read-only access."
  type        = list(string)
  default     = []
}

variable "node_ami_type" {
  description = "AMI type for managed node group."
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "node_capacity_type" {
  description = "Node capacity type."
  type        = string
  default     = "ON_DEMAND"
}

variable "node_instance_types" {
  description = "Node instance types."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired node count."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum node count."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum node count."
  type        = number
  default     = 3
}

variable "node_max_unavailable" {
  description = "Maximum unavailable nodes during update."
  type        = number
  default     = 1
}

variable "node_root_volume_size" {
  description = "Node root volume size."
  type        = number
  default     = 50
}

variable "node_root_volume_type" {
  description = "Node root volume type."
  type        = string
  default     = "gp3"
}

variable "node_imds_hop_limit" {
  description = "IMDS hop limit."
  type        = number
  default     = 1
}

variable "node_labels" {
  description = "Additional node labels."
  type        = map(string)
  default     = {}
}

variable "node_taints" {
  description = "Node taints."
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
variable "eks_addons" {
  description = "EKS managed add-ons to install."
  type = map(object({
    addon_version               = optional(string)
    service_account_role_arn    = optional(string)
    configuration_values        = optional(string)
    resolve_conflicts_on_create = optional(string)
    resolve_conflicts_on_update = optional(string)
  }))
  default = {}
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