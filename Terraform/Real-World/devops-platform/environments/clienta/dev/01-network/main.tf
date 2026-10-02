module "network" {
  source = "../../../../stacks/new-environment/01-network"

  client      = var.client
  environment = var.environment
  name_prefix = var.name_prefix

  vpc_cidr             = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  availability_zones         = var.availability_zones
  public_subnet_cidrs        = var.public_subnet_cidrs
  private_app_subnet_cidrs   = var.private_app_subnet_cidrs
  private_db_subnet_cidrs    = var.private_db_subnet_cidrs
  public_subnet_tags         = var.public_subnet_tags
  private_app_subnet_tags    = var.private_app_subnet_tags
  private_db_subnet_tags     = var.private_db_subnet_tags
  enable_nat_gateway         = var.enable_nat_gateway
  nat_gateway_mode           = var.nat_gateway_mode
  enable_db_subnet_nat_route = var.enable_db_subnet_nat_route

  egress_cidr_blocks            = var.egress_cidr_blocks
  enable_mysql_rule             = var.enable_mysql_rule
  enable_postgresql_rule        = var.enable_postgresql_rule
  karpenter_discovery_tag_value = var.karpenter_discovery_tag_value
  tags                          = var.tags
}
