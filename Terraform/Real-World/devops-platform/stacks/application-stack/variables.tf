# ── Identity ────────────────────────────────────────────────────────────────
variable "root_client" {
  description = "Root client / source reference client (e.g. clienta, test)."
  type        = string
}

variable "client_name" {
  description = "Target client identifier (e.g. example, clienta-prod)."
  type        = string
}

variable "product" {
  description = "Product name (e.g. PRODA, PRODC, PRODD)."
  type        = string
}

variable "service" {
  description = "Service name within the product (e.g. fe, be, proda-backend). When omitted, naming falls back to client-product-*."
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)."
  type        = string
}

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

# ── Networking ───────────────────────────────────────────────────────────────
# These are supplied by the wrapper main.tf from the 01-network remote state.
# They can also be passed explicitly for standalone use.
variable "vpc_id" {
  description = "VPC ID for all resources. Supplied from 01-network remote state by the wrapper."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private (DB) subnet IDs for RDS, ElastiCache, internal ALB. Supplied from 01-network remote state."
  type        = list(string)
}

variable "private_app_subnet_ids" {
  description = "Private app-tier subnet IDs (used for internal ALB instead of DB subnets when set)."
  type        = list(string)
  default     = []
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for external ALB."
  type        = list(string)
  default     = []
}

# ── ALB ─────────────────────────────────────────────────────────────────────
variable "create_alb" {
  description = "Create a new Application Load Balancer."
  type        = bool
  default     = false
}

variable "alb_use_existing" {
  description = "Look up an existing ALB by name instead of creating one."
  type        = bool
  default     = false
}

variable "alb_name" {
  description = "ALB name. Defaults to <client_name>-alb-internal or <client_name>-alb-external."
  type        = string
  default     = ""
}

variable "alb_internal" {
  description = "true = internal ALB; false = internet-facing."
  type        = bool
  default     = true
}

variable "alb_ingress_port" {
  description = "Primary application port for ALB listener / target group."
  type        = number
  default     = 80
}

# ── Route53 ─────────────────────────────────────────────────────────────────
variable "create_dns" {
  description = "Create Route53 A-alias records pointing to the ALB."
  type        = bool
  default     = false
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID."
  type        = string
  default     = ""
}

variable "service_hostnames" {
  description = "List of DNS hostnames to create as A-alias records to the ALB."
  type        = list(string)
  default     = []
}

# ── RDS PostgreSQL ───────────────────────────────────────────────────────────
variable "create_rds_postgres" {
  description = "Create a PostgreSQL RDS instance."
  type        = bool
  default     = false
}

variable "rds_postgres_name" {
  description = "RDS PostgreSQL identifier prefix. Defaults to <client>-<product>-<service>-pg."
  type        = string
  default     = ""
}

variable "rds_postgres_db_name" {
  description = "PostgreSQL database name."
  type        = string
  default     = "postgres"
}

variable "rds_postgres_username" {
  description = "PostgreSQL master username."
  type        = string
  default     = "dbadmin"
}

variable "rds_postgres_password" {
  description = "PostgreSQL master password."
  type        = string
  sensitive   = true
  default     = ""
}

variable "rds_postgres_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.medium"
}

variable "rds_postgres_skip_final_snapshot" {
  description = "Skip final snapshot on delete."
  type        = bool
  default     = true
}

variable "rds_postgres_deletion_protection" {
  description = "Enable deletion protection."
  type        = bool
  default     = false
}

# ── RDS MySQL ────────────────────────────────────────────────────────────────
variable "create_rds_mysql" {
  description = "Create a MySQL RDS instance."
  type        = bool
  default     = false
}

variable "rds_mysql_name" {
  description = "RDS MySQL identifier prefix. Defaults to <client>-<product>-<service>-mysql."
  type        = string
  default     = ""
}

variable "rds_mysql_db_name" {
  description = "MySQL database name."
  type        = string
  default     = ""
}

variable "rds_mysql_username" {
  description = "MySQL master username."
  type        = string
  default     = "dbadmin"
}

variable "rds_mysql_password" {
  description = "MySQL master password."
  type        = string
  sensitive   = true
  default     = ""
}

variable "rds_mysql_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.medium"
}

variable "rds_mysql_skip_final_snapshot" {
  description = "Skip final snapshot on delete."
  type        = bool
  default     = true
}

variable "rds_mysql_deletion_protection" {
  description = "Enable deletion protection."
  type        = bool
  default     = false
}

# ── ElastiCache Redis ────────────────────────────────────────────────────────
variable "create_elasticache" {
  description = "Create an ElastiCache Redis replication group."
  type        = bool
  default     = false
}

variable "elasticache_name" {
  description = "ElastiCache replication group name. Defaults to <client>-<product>-<service>-redis."
  type        = string
  default     = ""
}

variable "elasticache_node_type" {
  description = "ElastiCache node type."
  type        = string
  default     = "cache.t3.medium"
}

variable "elasticache_num_replicas" {
  description = "Number of replica nodes (0 = single-node)."
  type        = number
  default     = 0
}

# ── S3 Bucket ────────────────────────────────────────────────────────────────
variable "create_s3" {
  description = "Create an S3 bucket."
  type        = bool
  default     = false
}

variable "s3_bucket_name" {
  description = "S3 bucket name. Defaults to <client>-<product>-<service>-<account_id>."
  type        = string
  default     = ""
}

# ── SQS Queue ────────────────────────────────────────────────────────────────
variable "create_sqs" {
  description = "Create an SQS queue."
  type        = bool
  default     = false
}

variable "sqs_queue_name" {
  description = "SQS queue name. Defaults to <client>-<product>-<service>-<env>."
  type        = string
  default     = ""
}

variable "sqs_create_dlq" {
  description = "Also create a dead-letter queue."
  type        = bool
  default     = true
}

variable "sqs_max_receive_count" {
  description = "Max receive count before message moves to DLQ."
  type        = number
  default     = 5
}

# ── EKS connectivity ────────────────────────────────────────────────────────
variable "eks_security_group_ids" {
  description = "EKS node/cluster SG IDs granted access to RDS and ElastiCache."
  type        = list(string)
  default     = []
}

# ── Common ───────────────────────────────────────────────────────────────────
variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}
