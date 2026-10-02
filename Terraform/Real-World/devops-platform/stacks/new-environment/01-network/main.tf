locals {
  name_prefix = var.name_prefix != null && var.name_prefix != "" ? var.name_prefix : "${var.client}-${var.environment}"

  common_tags = merge(var.tags, {
    Client      = var.client
    Environment = var.environment
    ManagedBy   = "devops-launchpad"
    Stack       = "01-network"
  })
}

module "vpc" {
  source = "../../../modules/network/vpc"

  vpc_name             = "${local.name_prefix}-vpc"
  vpc_cidr             = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames
  tags                 = local.common_tags
}

module "subnets" {
  source = "../../../modules/network/subnets"

  name_prefix              = local.name_prefix
  vpc_id                   = module.vpc.vpc_id
  availability_zones       = var.availability_zones
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs

  public_subnet_tags      = var.public_subnet_tags
  private_app_subnet_tags = var.private_app_subnet_tags
  private_db_subnet_tags  = var.private_db_subnet_tags

  tags = local.common_tags
}

module "routing" {
  source = "../../../modules/network/routing"

  name_prefix                = local.name_prefix
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.subnets.public_subnet_ids
  private_app_subnet_ids     = module.subnets.private_app_subnet_ids
  private_db_subnet_ids      = module.subnets.private_db_subnet_ids
  enable_nat_gateway         = var.enable_nat_gateway
  nat_gateway_mode           = var.nat_gateway_mode
  enable_db_subnet_nat_route = var.enable_db_subnet_nat_route
  internet_cidr_block        = var.internet_cidr_block

  tags = local.common_tags
}

module "security_groups" {
  source = "../../../modules/security/security-groups"

  name_prefix                   = local.name_prefix
  vpc_id                        = module.vpc.vpc_id
  egress_cidr_blocks            = var.egress_cidr_blocks
  enable_mysql_rule             = var.enable_mysql_rule
  enable_postgresql_rule        = var.enable_postgresql_rule
  karpenter_discovery_tag_value = var.karpenter_discovery_tag_value
  tags                          = local.common_tags
}
