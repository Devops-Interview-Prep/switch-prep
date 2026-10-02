variable "repo_name" {
  type = string
}

variable "keep_image_count" {
  type    = number
  default = 20
}

variable "tags" {
  type    = map(string)
  default = {}
}
