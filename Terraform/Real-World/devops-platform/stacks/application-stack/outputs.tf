# ── ALB ──────────────────────────────────────────────────────────────────────
output "alb_dns_name" {
  description = "ALB DNS name (created or looked-up)."
  value       = local.alb_dns_name
}

output "alb_zone_id" {
  description = "ALB hosted zone ID (created or looked-up)."
  value       = local.alb_zone_id
}

output "alb_arn" {
  description = "ALB ARN (only set when create_alb = true)."
  value       = var.create_alb && length(module.alb) > 0 ? module.alb[0].alb_arn : ""
}

# ── RDS PostgreSQL ────────────────────────────────────────────────────────────
output "rds_postgres_endpoint" {
  description = "RDS PostgreSQL endpoint."
  value       = var.create_rds_postgres && length(module.rds_postgres) > 0 ? module.rds_postgres[0].endpoint : ""
}

output "rds_postgres_port" {
  description = "RDS PostgreSQL port."
  value       = var.create_rds_postgres && length(module.rds_postgres) > 0 ? module.rds_postgres[0].port : null
}

output "rds_postgres_db_name" {
  description = "RDS PostgreSQL database name."
  value       = var.create_rds_postgres && length(module.rds_postgres) > 0 ? module.rds_postgres[0].db_name : ""
}

# ── RDS MySQL ─────────────────────────────────────────────────────────────────
output "rds_mysql_endpoint" {
  description = "RDS MySQL endpoint."
  value       = var.create_rds_mysql && length(module.rds_mysql) > 0 ? module.rds_mysql[0].endpoint : ""
}

output "rds_mysql_port" {
  description = "RDS MySQL port."
  value       = var.create_rds_mysql && length(module.rds_mysql) > 0 ? module.rds_mysql[0].port : null
}

output "rds_mysql_db_name" {
  description = "RDS MySQL database name."
  value       = var.create_rds_mysql && length(module.rds_mysql) > 0 ? module.rds_mysql[0].db_name : ""
}

# ── ElastiCache ───────────────────────────────────────────────────────────────
output "elasticache_primary_endpoint" {
  description = "ElastiCache Redis primary endpoint."
  value       = var.create_elasticache && length(module.elasticache) > 0 ? module.elasticache[0].primary_endpoint : ""
}

output "elasticache_reader_endpoint" {
  description = "ElastiCache Redis reader endpoint."
  value       = var.create_elasticache && length(module.elasticache) > 0 ? module.elasticache[0].reader_endpoint : ""
}

output "elasticache_port" {
  description = "ElastiCache Redis port."
  value       = var.create_elasticache && length(module.elasticache) > 0 ? module.elasticache[0].port : null
}

# ── S3 ────────────────────────────────────────────────────────────────────────
output "s3_bucket_name" {
  description = "S3 bucket name."
  value       = var.create_s3 && length(module.s3) > 0 ? module.s3[0].bucket_name : ""
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN."
  value       = var.create_s3 && length(module.s3) > 0 ? module.s3[0].bucket_arn : ""
}

# ── SQS ───────────────────────────────────────────────────────────────────────
output "sqs_queue_url" {
  description = "SQS queue URL."
  value       = var.create_sqs && length(module.sqs) > 0 ? module.sqs[0].queue_url : ""
}

output "sqs_queue_arn" {
  description = "SQS queue ARN."
  value       = var.create_sqs && length(module.sqs) > 0 ? module.sqs[0].queue_arn : ""
}

output "sqs_queue_name" {
  description = "SQS queue name."
  value       = var.create_sqs && length(module.sqs) > 0 ? module.sqs[0].queue_name : ""
}

output "sqs_dlq_url" {
  description = "SQS dead-letter queue URL."
  value       = var.create_sqs && length(module.sqs) > 0 ? module.sqs[0].dlq_url : ""
}
