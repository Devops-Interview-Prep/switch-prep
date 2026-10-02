variable "name" {
  description = "Prefix for all resources (e.g. clienta-dev-proda)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the Solr instance will be placed"
  type        = string
}

variable "subnet_id" {
  description = "Private subnet ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "m5.xlarge"
}

variable "solr_version" {
  description = "Apache Solr version to install"
  type        = string
  default     = "8.11.4"
}

variable "solr_port" {
  description = "Port Solr will listen on"
  type        = number
  default     = 8983
}

variable "solr_auth_user" {
  description = "Solr basic-auth username"
  type        = string
  default     = "example.application.user"
}

variable "solr_auth_password" {
  description = "Solr basic-auth password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "heap_size_gb" {
  description = "JVM heap size in GB"
  type        = number
  default     = 4
}

variable "data_volume_gb" {
  description = "EBS root volume size in GB"
  type        = number
  default     = 100
}

variable "collections" {
  description = "List of Solr collection names to pre-create"
  type        = list(string)
  default     = []
}

variable "collection_configs" {
  description = "Map of collection name → JSON schema config (from SSM fetch)"
  type        = map(string)
  default     = {}
}

variable "allow_cidr_blocks" {
  description = "CIDR blocks allowed to reach Solr port 8983"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
