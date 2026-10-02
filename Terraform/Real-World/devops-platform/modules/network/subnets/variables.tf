variable "name_prefix" {
  description = "Name prefix for subnet resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where subnets will be created."
  type        = string
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

variable "tags" {
  description = "Common tags to apply to all subnet resources."
  type        = map(string)
  default     = {}
}