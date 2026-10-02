variable "name_prefix" {
  description = "Name prefix for routing resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where routing resources will be created."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs where NAT gateways will be created."
  type        = list(string)
  default     = []
}

variable "private_app_subnet_ids" {
  description = "Private application subnet IDs to associate with private route tables."
  type        = list(string)
  default     = []
}

variable "private_db_subnet_ids" {
  description = "Private database subnet IDs to associate with private DB route tables."
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT gateways for private subnet outbound internet access."
  type        = bool
  default     = true
}

variable "nat_gateway_mode" {
  description = "NAT Gateway deployment mode. Use single for lower cost, per_az for high availability."
  type        = string
  default     = "single"

  validation {
    condition     = contains(["single", "per_az"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode must be either single or per_az."
  }
}

variable "enable_db_subnet_nat_route" {
  description = "Whether private DB subnets should have outbound internet access through NAT."
  type        = bool
  default     = false
}

variable "internet_cidr_block" {
  description = "CIDR block used for default internet route."
  type        = string
  default     = "0.0.0.0/0"
}

variable "tags" {
  description = "Common tags to apply to routing resources."
  type        = map(string)
  default     = {}
}