variable "client" {
  description = "Client identifier."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "name_prefix" {
  description = "Optional name prefix. If empty, client-environment is used."
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "Optional EKS cluster name. If empty, name_prefix-eks is used."
  type        = string
  default     = null
}

variable "cluster_version" {
  description = "EKS Kubernetes version."
  type        = string
}

variable "cluster_subnet_ids" {
  description = "Private subnet IDs used by EKS control plane ENIs."
  type        = list(string)
}

variable "node_subnet_ids" {
  description = "Private subnet IDs where managed node group nodes run."
  type        = list(string)
}

variable "cluster_security_group_ids" {
  description = "Security group IDs attached to the EKS control plane."
  type        = list(string)
}

variable "node_security_group_ids" {
  description = "Security group IDs attached to worker nodes."
  type        = list(string)
}

variable "kms_deletion_window_in_days" {
  description = "KMS key deletion window."
  type        = number
  default     = 30
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
  description = "Attach AmazonEKS_CNI_Policy to the node role. For final hardened setup, move this to VPC CNI IRSA in 03-eks-platform."
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
  description = "IAM principal ARNs with developer edit access."
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
  description = "Node group capacity type."
  type        = string
  default     = "ON_DEMAND"
}

variable "node_instance_types" {
  description = "Node group instance types."
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
  description = "Maximum unavailable nodes during updates."
  type        = number
  default     = 1
}

variable "node_root_volume_size" {
  description = "Node root volume size in GiB."
  type        = number
  default     = 50
}

variable "node_root_volume_type" {
  description = "Node root volume type."
  type        = string
  default     = "gp3"
}

variable "node_imds_hop_limit" {
  description = "IMDS hop limit. Use 1 for stricter node-level metadata access."
  type        = number
  default     = 1
}

variable "node_labels" {
  description = "Additional labels for system node group."
  type        = map(string)
  default     = {}
}

variable "node_taints" {
  description = "Optional taints for system node group."
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