variable "vpc_id" {
  description = "ID of the existing VPC to augment"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name — used for subnet tagging"
  type        = string
}

variable "missing_components" {
  description = "List of component keys to create (from /api/hybrid/analyze-vpc response)"
  type        = list(string)
  default     = []
  # Valid values: "igw", "subnet-public-<az>", "subnet-private-app-<az>",
  #               "subnet-private-db-<az>", "nat-gw-<az>"
}

variable "existing_public_subnet_ids" {
  description = "Public subnet IDs already in the VPC, indexed by AZ order — used to place new NAT GWs"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
