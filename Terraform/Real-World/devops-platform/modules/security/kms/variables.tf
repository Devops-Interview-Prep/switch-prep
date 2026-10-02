variable "alias_name" {
  description = "KMS alias name without alias/ prefix."
  type        = string
}

variable "description" {
  description = "KMS key description."
  type        = string
}

variable "deletion_window_in_days" {
  description = "KMS key deletion window."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}