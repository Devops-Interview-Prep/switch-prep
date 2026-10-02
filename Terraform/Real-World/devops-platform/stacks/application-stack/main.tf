resource "random_password" "rds_mysql" {
  count   = var.create_rds_mysql ? 1 : 0
  length  = 16
  special = false
}

resource "random_password" "rds_postgres" {
  count   = var.create_rds_postgres ? 1 : 0
  length  = 16
  special = false
}

locals {
  name_prefix = var.service != "" ? "${var.client_name}-${lower(var.product)}-${lower(var.service)}" : "${var.client_name}-${lower(var.product)}"

  alb_name = var.alb_name != "" ? var.alb_name : (
    var.alb_internal
    ? "${var.client_name}-alb-internal"
    : "${var.client_name}-alb-external"
  )

  # Internal ALB prefers app-tier subnets; falls back to DB subnets when not set.
  alb_subnets = var.alb_internal ? (
    length(var.private_app_subnet_ids) > 0 ? var.private_app_subnet_ids : var.private_subnet_ids
  ) : var.public_subnet_ids

  rds_pg_name    = var.rds_postgres_name != "" ? var.rds_postgres_name : "${local.name_prefix}-pg"
  rds_mysql_name = var.rds_mysql_name != "" ? var.rds_mysql_name : "${local.name_prefix}-mysql"
  ec_name        = var.elasticache_name != "" ? var.elasticache_name : "${local.name_prefix}-redis"
  s3_name        = var.s3_bucket_name != "" ? var.s3_bucket_name : "${local.name_prefix}-${data.aws_caller_identity.current.account_id}"
  sqs_name       = var.sqs_queue_name != "" ? var.sqs_queue_name : (var.service != "" ? "${var.client_name}-${lower(var.product)}-${lower(var.service)}-${var.environment}" : "${var.client_name}-${lower(var.product)}-${var.environment}")

  rds_mysql_password    = var.rds_mysql_password != "" ? var.rds_mysql_password : (var.create_rds_mysql ? random_password.rds_mysql[0].result : "")
  rds_postgres_password = var.rds_postgres_password != "" ? var.rds_postgres_password : (var.create_rds_postgres ? random_password.rds_postgres[0].result : "")

  common_tags = merge(var.tags, {
    root_client = var.root_client
    client      = var.client_name
    product     = var.product
    env         = var.environment
    managed_by  = "terraform"
  })
}

data "aws_caller_identity" "current" {}

data "aws_vpc" "this" {
  id = var.vpc_id
}

# ── ALB: look up existing ─────────────────────────────────────────────────────
data "aws_lb" "existing" {
  count = var.alb_use_existing && !var.create_alb ? 1 : 0
  name  = local.alb_name
}

# ── ALB: create new ───────────────────────────────────────────────────────────
module "alb" {
  count  = var.create_alb ? 1 : 0
  source = "../../modules/alb"

  name       = local.alb_name
  vpc_id     = var.vpc_id
  subnet_ids = local.alb_subnets
  internal   = var.alb_internal
  app_port   = var.alb_ingress_port
  tags       = local.common_tags
}

# ── Route53 records ───────────────────────────────────────────────────────────
# One record per hostname in var.service_hostnames.
# Requires at least one of create_alb or alb_use_existing to be true.
locals {
  alb_dns_name = (
    var.create_alb && length(module.alb) > 0
    ? module.alb[0].alb_dns_name
    : (var.alb_use_existing && length(data.aws_lb.existing) > 0
      ? data.aws_lb.existing[0].dns_name
    : "")
  )
  alb_zone_id = (
    var.create_alb && length(module.alb) > 0
    ? module.alb[0].alb_zone_id
    : (var.alb_use_existing && length(data.aws_lb.existing) > 0
      ? data.aws_lb.existing[0].zone_id
    : "")
  )
}

module "dns" {
  for_each = (var.create_dns && local.alb_dns_name != "" && local.alb_zone_id != "") ? toset(var.service_hostnames) : toset([])
  source   = "../../modules/route53"

  hosted_zone_id = var.hosted_zone_id
  hosted_zone    = ""
  subdomain      = each.key
  record_type    = "ALIAS"
  alb_dns_name   = local.alb_dns_name
  alb_zone_id    = local.alb_zone_id
  tags           = local.common_tags
}

# ── RDS PostgreSQL ────────────────────────────────────────────────────────────
module "rds_postgres" {
  count  = var.create_rds_postgres ? 1 : 0
  source = "../../modules/rds-postgres"

  name                   = local.rds_pg_name
  vpc_id                 = var.vpc_id
  db_subnet_ids          = var.private_subnet_ids
  allowed_cidr_blocks    = [data.aws_vpc.this.cidr_block]
  eks_security_group_ids = var.eks_security_group_ids
  db_name                = var.rds_postgres_db_name
  username               = var.rds_postgres_username
  password               = local.rds_postgres_password
  instance_class         = var.rds_postgres_instance_class
  skip_final_snapshot    = var.rds_postgres_skip_final_snapshot
  deletion_protection    = var.rds_postgres_deletion_protection
  tags                   = local.common_tags
}

# ── RDS MySQL ─────────────────────────────────────────────────────────────────
module "rds_mysql" {
  count  = var.create_rds_mysql ? 1 : 0
  source = "../../modules/rds-mysql"

  name                   = local.rds_mysql_name
  vpc_id                 = var.vpc_id
  db_subnet_ids          = var.private_subnet_ids
  allowed_cidr_blocks    = [data.aws_vpc.this.cidr_block]
  eks_security_group_ids = var.eks_security_group_ids
  db_name                = var.rds_mysql_db_name
  username               = var.rds_mysql_username
  password               = local.rds_mysql_password
  instance_class         = var.rds_mysql_instance_class
  skip_final_snapshot    = var.rds_mysql_skip_final_snapshot
  deletion_protection    = var.rds_mysql_deletion_protection
  tags                   = local.common_tags
}

# ── ElastiCache Redis ─────────────────────────────────────────────────────────
module "elasticache" {
  count  = var.create_elasticache ? 1 : 0
  source = "../../modules/elasticache-redis"

  name                   = local.ec_name
  vpc_id                 = var.vpc_id
  subnet_ids             = var.private_subnet_ids
  allowed_cidr_blocks    = [data.aws_vpc.this.cidr_block]
  eks_security_group_ids = var.eks_security_group_ids
  node_type              = var.elasticache_node_type
  num_replicas           = var.elasticache_num_replicas
  tags                   = local.common_tags
}

# ── S3 Bucket ─────────────────────────────────────────────────────────────────
module "s3" {
  count  = var.create_s3 ? 1 : 0
  source = "../../modules/s3-bucket"

  bucket_name = local.s3_name
  tags        = local.common_tags
}

# ── SQS Queue ─────────────────────────────────────────────────────────────────
module "sqs" {
  count  = var.create_sqs ? 1 : 0
  source = "../../modules/sqs-queue"

  queue_name        = local.sqs_name
  create_dlq        = var.sqs_create_dlq
  max_receive_count = var.sqs_max_receive_count
  tags              = local.common_tags
}
