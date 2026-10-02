variable "name_prefix" {
  description = "Name prefix for security group resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created."
  type        = string
}

variable "egress_cidr_blocks" {
  description = "CIDR blocks allowed for outbound traffic."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_mysql_rule" {
  description = "Whether to allow MySQL traffic from app SG to DB SG."
  type        = bool
  default     = true
}

variable "enable_postgresql_rule" {
  description = "Whether to allow PostgreSQL traffic from app SG to DB SG."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags to apply to security group resources."
  type        = map(string)
  default     = {}
}
variable "karpenter_discovery_tag_value" {
  description = "Optional Karpenter discovery tag value for node security group."
  type        = string
  default     = null
}