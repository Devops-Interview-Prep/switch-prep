# ── Dependency: network layer outputs ──
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "example-tf-state-123456789012-us-east-1"
    key    = "launchpad/environments/shared/dev/01-network/terraform.tfstate"
    region = "us-east-1"
  }
}

module "app_stack" {
  source = "../../../../../../stacks/application-stack"

  root_client = "devops"
  client_name = "devops"
  product     = "PRODB"
  environment = "dev"
  aws_region  = "us-east-1"

  vpc_id                 = data.terraform_remote_state.network.outputs.vpc_id
  private_subnet_ids     = data.terraform_remote_state.network.outputs.private_db_subnet_ids
  private_app_subnet_ids = data.terraform_remote_state.network.outputs.private_app_subnet_ids
  public_subnet_ids      = data.terraform_remote_state.network.outputs.public_subnet_ids
  eks_security_group_ids = compact([
    try(data.terraform_remote_state.network.outputs.eks_nodes_security_group_id, ""),
    try(data.terraform_remote_state.network.outputs.eks_cluster_security_group_id, ""),
  ])

  create_rds_postgres = true
  create_s3           = true
  create_rds_mysql    = true
  create_elasticache  = true
}

output "stack_outputs" {
  value     = module.app_stack
  sensitive = true
}
