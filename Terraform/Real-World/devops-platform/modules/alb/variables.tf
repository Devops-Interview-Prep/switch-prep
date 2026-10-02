variable "name" {
  description = "ALB name (e.g. clienta-dev-ra)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the ALB (at least 2 AZs)"
  type        = list(string)
}

variable "internal" {
  description = "Whether the ALB is internal"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "allowed_cidr_blocks" {
  description = "CIDRs allowed to reach ALB listener ports"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "listener_ports" {
  description = "Ports the ALB listens on (drives SG ingress rules)"
  type        = list(number)
  default     = [28998, 28092, 28090]
}

variable "app_port" {
  description = "Main application target group port"
  type        = number
  default     = 28998
}

variable "control_plane_port" {
  description = "Control-plane target group port"
  type        = number
  default     = 28092
}

variable "orchestrator_port" {
  description = "Orchestrator target group port"
  type        = number
  default     = 28090
}

variable "app_health_path" {
  description = "Health check path for the main app target group"
  type        = string
  default     = "/app/login"
}

variable "api_health_path" {
  description = "Health check path for API (control-plane / orchestrator) target groups"
  type        = string
  default     = "/api/health"
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
