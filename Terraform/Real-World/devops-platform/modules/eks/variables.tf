variable "cluster_name" {
  type = string
}

variable "k8s_version" {
  type    = string
  default = "1.31"
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "node_instance_type" {
  type    = string
  default = "t3.xlarge"
}

variable "node_count" {
  type    = number
  default = 3
}

variable "tags" {
  type    = map(string)
  default = {}
}
