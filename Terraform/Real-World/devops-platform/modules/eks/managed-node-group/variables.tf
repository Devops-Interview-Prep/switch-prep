variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "node_group_name" {
  description = "EKS managed node group name."
  type        = string
}

variable "node_role_arn" {
  description = "IAM role ARN for EKS worker nodes."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs where worker nodes will run."
  type        = list(string)
}

variable "node_security_group_ids" {
  description = "Security group IDs attached to worker node ENIs through launch template."
  type        = list(string)
}

variable "ami_type" {
  description = "AMI type for the managed node group."
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "capacity_type" {
  description = "Capacity type for the node group. Valid values are ON_DEMAND or SPOT."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "capacity_type must be either ON_DEMAND or SPOT."
  }
}

variable "instance_types" {
  description = "EC2 instance types for the node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "desired_size" {
  description = "Desired number of nodes."
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of nodes."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of nodes."
  type        = number
  default     = 3
}

variable "max_unavailable" {
  description = "Maximum unavailable nodes during node group updates."
  type        = number
  default     = 1
}

variable "root_device_name" {
  description = "Root block device name."
  type        = string
  default     = "/dev/xvda"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 50
}

variable "root_volume_type" {
  description = "Root EBS volume type."
  type        = string
  default     = "gp3"
}

variable "imds_hop_limit" {
  description = "IMDS hop limit. Keep 1 for stricter node-level access unless workload requirements need 2."
  type        = number
  default     = 1
}

variable "labels" {
  description = "Kubernetes labels to apply to nodes."
  type        = map(string)
  default     = {}
}

variable "taints" {
  description = "Kubernetes taints to apply to nodes."
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []

  validation {
    condition = alltrue([
      for taint in var.taints : contains(["NO_SCHEDULE", "NO_EXECUTE", "PREFER_NO_SCHEDULE"], taint.effect)
    ])
    error_message = "taint effect must be one of: NO_SCHEDULE, NO_EXECUTE, PREFER_NO_SCHEDULE."
  }
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}