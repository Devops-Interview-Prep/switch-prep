variable "client" {
  description = "Client identifier, for example clienta, clientb, clientc."
  type        = string
}

variable "environment" {
  description = "Environment name, for example dev, test, uat, prod."
  type        = string
}

variable "name_prefix" {
  description = "Optional name prefix for all network resources. If empty, client-environment is used."
  type        = string
  default     = null
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
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
  description = "Availability zones for subnet placement."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
  default     = []
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private application subnets."
  type        = list(string)
  default     = []
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for private database subnets."
  type        = list(string)
  default     = []
}

variable "public_subnet_tags" {
  description = "Additional tags for public subnets."
  type        = map(string)
  default = {
    "kubernetes.io/role/elb" = "1"
  }
}

variable "private_app_subnet_tags" {
  description = "Additional tags for private application subnets."
  type        = map(string)
  default = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

variable "private_db_subnet_tags" {
  description = "Additional tags for private DB subnets."
  type        = map(string)
  default     = {}
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT gateways."
  type        = bool
  default     = true
}

variable "nat_gateway_mode" {
  description = "NAT Gateway mode. Use single for lower cost, per_az for higher availability."
  type        = string
  default     = "single"

  validation {
    condition     = contains(["single", "per_az"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode must be either single or per_az."
  }
}

variable "enable_db_subnet_nat_route" {
  description = "Whether DB subnets should have outbound internet access through NAT."
  type        = bool
  default     = false
}

variable "internet_cidr_block" {
  description = "Default internet route CIDR."
  type        = string
  default     = "0.0.0.0/0"
}

variable "egress_cidr_blocks" {
  description = "CIDR blocks allowed for outbound security group traffic."
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
  description = "Additional common tags."
  type        = map(string)
  default     = {}
}
variable "karpenter_discovery_tag_value" {
  description = "Optional Karpenter discovery tag value for EKS node security group."
  type        = string
  default     = null
}