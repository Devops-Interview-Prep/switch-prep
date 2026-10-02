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
  description = "Optional resource name prefix."
  type        = string
  default     = null
}

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC."
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC."
  type        = bool
  default     = true
}

variable "availability_zones" {
  description = "Availability zones."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs."
  type        = list(string)
}

variable "private_app_subnet_cidrs" {
  description = "Private application subnet CIDRs."
  type        = list(string)
}

variable "private_db_subnet_cidrs" {
  description = "Private database subnet CIDRs."
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT Gateway."
  type        = bool
  default     = true
}

variable "nat_gateway_mode" {
  description = "NAT mode: single or per_az."
  type        = string
  default     = "single"
}

variable "enable_db_subnet_nat_route" {
  description = "Whether DB subnets should route outbound through NAT."
  type        = bool
  default     = false
}

variable "egress_cidr_blocks" {
  description = "Allowed egress CIDR blocks."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_mysql_rule" {
  description = "Allow MySQL from app SG to DB SG."
  type        = bool
  default     = true
}

variable "enable_postgresql_rule" {
  description = "Allow PostgreSQL from app SG to DB SG."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
variable "public_subnet_tags" {
  description = "Additional public subnet tags."
  type        = map(string)
  default = {
    "kubernetes.io/role/elb" = "1"
  }
}

variable "private_app_subnet_tags" {
  description = "Additional private app subnet tags."
  type        = map(string)
  default = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

variable "private_db_subnet_tags" {
  description = "Additional private DB subnet tags."
  type        = map(string)
  default     = {}
}
variable "karpenter_discovery_tag_value" {
  description = "Karpenter discovery tag value."
  type        = string
  default     = null
}