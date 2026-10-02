variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "addons" {
  description = "Map of EKS managed add-ons."
  type = map(object({
    addon_version               = optional(string)
    service_account_role_arn    = optional(string)
    configuration_values        = optional(string)
    resolve_conflicts_on_create = optional(string)
    resolve_conflicts_on_update = optional(string)
  }))
  default = {}
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}