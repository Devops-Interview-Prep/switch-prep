# Hybrid VPC module — adds missing subnets/NAT GWs to an existing VPC
# Does NOT touch existing resources; only creates what's listed in var.missing_components

terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

data "aws_vpc" "existing" {
  id = var.vpc_id
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs          = slice(data.aws_availability_zones.available.names, 0, 3)
  cluster_name = var.cluster_name
  common_tags  = merge(var.tags, { ManagedBy = "devops-launchpad", VpcId = var.vpc_id })

  # Derive subnet CIDRs from VPC CIDR using same layout as new-environment module
  vpc_cidr                 = data.aws_vpc.existing.cidr_block
  public_subnet_cidrs      = [for i in range(3) : cidrsubnet(local.vpc_cidr, 10, i)]
  private_app_subnet_cidrs = [for i in range(3) : cidrsubnet(local.vpc_cidr, 4, i + 1)]
  private_db_subnet_cidrs  = [for i in range(3) : cidrsubnet(local.vpc_cidr, 8, 200 + i)]

  add_igw              = contains(var.missing_components, "igw")
  add_public_subnets   = [for az in local.azs : az if contains(var.missing_components, "subnet-public-${az}")]
  add_priv_app_subnets = [for az in local.azs : az if contains(var.missing_components, "subnet-private-app-${az}")]
  add_priv_db_subnets  = [for az in local.azs : az if contains(var.missing_components, "subnet-private-db-${az}")]
  add_nat_gws          = [for az in local.azs : az if contains(var.missing_components, "nat-gw-${az}")]
}

# IGW (only if missing)
resource "aws_internet_gateway" "new" {
  count  = local.add_igw ? 1 : 0
  vpc_id = data.aws_vpc.existing.id
  tags   = merge(local.common_tags, { Name = "${var.vpc_id}-igw" })
}

# Public subnets
resource "aws_subnet" "public_new" {
  for_each = toset(local.add_public_subnets)

  vpc_id                  = data.aws_vpc.existing.id
  cidr_block              = local.public_subnet_cidrs[index(local.azs, each.value)]
  availability_zone       = each.value
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name                                          = "${var.vpc_id}-public-${each.value}"
    Tier                                          = "public"
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  })
}

# Private-app subnets
resource "aws_subnet" "private_app_new" {
  for_each = toset(local.add_priv_app_subnets)

  vpc_id            = data.aws_vpc.existing.id
  cidr_block        = local.private_app_subnet_cidrs[index(local.azs, each.value)]
  availability_zone = each.value

  tags = merge(local.common_tags, {
    Name                                          = "${var.vpc_id}-private-app-${each.value}"
    Tier                                          = "private-app"
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
    "karpenter.sh/discovery"                      = local.cluster_name
  })
}

# Private-db subnets
resource "aws_subnet" "private_db_new" {
  for_each = toset(local.add_priv_db_subnets)

  vpc_id            = data.aws_vpc.existing.id
  cidr_block        = local.private_db_subnet_cidrs[index(local.azs, each.value)]
  availability_zone = each.value

  tags = merge(local.common_tags, {
    Name = "${var.vpc_id}-private-db-${each.value}"
    Tier = "private-db"
  })
}

# EIPs and NAT GWs (only for AZs that have a public subnet)
resource "aws_eip" "nat_new" {
  for_each   = toset(local.add_nat_gws)
  domain     = "vpc"
  tags       = merge(local.common_tags, { Name = "${var.vpc_id}-nat-eip-${each.value}" })
  depends_on = [aws_internet_gateway.new]
}

resource "aws_nat_gateway" "new" {
  for_each      = toset(local.add_nat_gws)
  allocation_id = aws_eip.nat_new[each.value].id
  # Place in the public subnet for this AZ (new or existing)
  subnet_id  = try(aws_subnet.public_new[each.value].id, var.existing_public_subnet_ids[index(local.add_nat_gws, each.value)])
  tags       = merge(local.common_tags, { Name = "${var.vpc_id}-nat-${each.value}" })
  depends_on = [aws_internet_gateway.new]
}
