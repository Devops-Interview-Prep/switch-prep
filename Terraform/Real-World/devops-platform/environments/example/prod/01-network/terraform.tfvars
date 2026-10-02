aws_region  = "us-east-1"
client      = "example"
environment = "prod"
name_prefix = "example-prod"

vpc_cidr = "10.150.0.0/16"

availability_zones = [
  "us-east-1a",
  "us-east-1b",
  "us-east-1c"
]

public_subnet_cidrs = [
  "10.150.0.0/26",
  "10.150.0.64/26",
  "10.150.0.128/26"
]

private_app_subnet_cidrs = [
  "10.150.16.0/20",
  "10.150.32.0/20",
  "10.150.48.0/20"
]

private_db_subnet_cidrs = [
  "10.150.80.0/24",
  "10.150.81.0/24",
  "10.150.82.0/24"
]

public_subnet_tags = {
  "kubernetes.io/role/elb" = "1"
}

private_app_subnet_tags = {
  "kubernetes.io/role/internal-elb" = "1"
  "karpenter.sh/discovery"          = "example-prod-eks"
}

private_db_subnet_tags = {}

karpenter_discovery_tag_value = "example-prod-eks"

enable_nat_gateway         = true
nat_gateway_mode           = "single"
enable_db_subnet_nat_route = false

enable_mysql_rule      = true
enable_postgresql_rule = true

tags = {
  Project   = "devops-launchpad"
  Owner     = "devops"
  Terraform = "true"
}
