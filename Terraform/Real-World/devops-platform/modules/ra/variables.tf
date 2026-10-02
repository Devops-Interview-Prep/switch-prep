variable "name" {
  description = "Prefix for all resources (e.g. clienta-dev-ra)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EC2 instance will be placed"
  type        = string
}

variable "subnet_id" {
  description = "Private subnet ID for the EC2 instance"
  type        = string
}

variable "ami_id" {
  description = "AMI ID (Amazon Linux 2023 recommended)"
  type        = string
  default     = "ami-0c6e5f085630eae83"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "r6a.xlarge"
}

variable "instance_count" {
  description = "Number of EC2 instances to provision (all identical, all registered to ALB target groups)"
  type        = number
  default     = 1
}

variable "root_volume_gb" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 50
}

# ── Application ports ─────────────────────────────────────────────────────────

variable "app_port" {
  description = "Main application port (Roster Automation UI)"
  type        = number
  default     = 28998
}

variable "control_plane_port" {
  description = "Control plane API port"
  type        = number
  default     = 28092
}

variable "orchestrator_port" {
  description = "Orchestrator API port"
  type        = number
  default     = 28090
}

variable "allow_cidr_blocks" {
  description = "Additional CIDR blocks allowed to reach application ports (VPC CIDR is always included)"
  type        = list(string)
  default     = []
}

# ── Deployment configuration ──────────────────────────────────────────────────

variable "ecr_registry" {
  description = "ECR registry URL (e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com)"
  type        = string
  default     = "123456789012.dkr.ecr.us-east-1.amazonaws.com"
}

variable "ecr_region" {
  description = "AWS region for ECR login"
  type        = string
  default     = "us-east-1"
}

variable "rds_secret_name" {
  description = "Secrets Manager secret name holding the RDS credentials (created when RDS is provisioned)"
  type        = string
}

variable "s3_bucket" {
  description = "S3 bucket holding the deploy scripts (00_install_from_s3.sh, 01_create_example_layout.sh)"
  type        = string
  default     = "clienta-deployment-ra"
}

variable "s3_deploy_prefix" {
  description = "S3 key prefix under s3_bucket where deploy scripts live"
  type        = string
  default     = "example-e2e-deploy"
}

variable "env_secret_name" {
  description = "Secrets Manager secret whose SecretString is the full .env file for Docker Compose"
  type        = string
  default     = "clienta-deployment-ra/env"
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
