variable "name_prefix" {
  description = "Name prefix for EKS IAM roles."
  type        = string
}

variable "attach_cni_policy_to_node_role" {
  description = "Whether to attach AmazonEKS_CNI_Policy to the node role. For production, prefer a separate IRSA role for VPC CNI."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}