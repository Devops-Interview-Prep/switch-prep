variable "hosted_zone_id" {
  type = string
}

variable "hosted_zone" {
  type = string
}

variable "subdomain" {
  type = string
}

variable "record_type" {
  type    = string
  default = "ALIAS"
  validation {
    condition     = contains(["ALIAS", "CNAME"], var.record_type)
    error_message = "Must be ALIAS or CNAME."
  }
}

variable "alb_dns_name" {
  type    = string
  default = ""
}

variable "alb_zone_id" {
  type    = string
  default = ""
}

variable "cname_target" {
  type    = string
  default = ""
}

variable "ttl" {
  type    = number
  default = 300
}

variable "tags" {
  type    = map(string)
  default = {}
}
