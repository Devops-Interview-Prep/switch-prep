variable "name" {
  description = "Resource name prefix (e.g. clienta-dev-prodd)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the ElastiCache subnet group"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect on port 6379"
  type        = list(string)
  default     = []
}

variable "eks_security_group_ids" {
  description = "EKS node/cluster security group IDs allowed to connect on port 6379"
  type        = list(string)
  default     = []
}

variable "node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.1"
}

variable "num_replicas" {
  description = "Number of replica nodes (0 = single-node)"
  type        = number
  default     = 0
}

variable "auth_token" {
  description = "Redis AUTH token (leave empty to disable)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
