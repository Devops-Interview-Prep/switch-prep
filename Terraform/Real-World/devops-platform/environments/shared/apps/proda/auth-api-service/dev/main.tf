# ── Dependency: network layer outputs (environments/shared/dev/01-network) ──
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "example-tf-state-123456789012-us-east-1"
    key    = "launchpad/environments/shared/dev/01-network/terraform.tfstate"
    region = "us-east-1"
  }
}

# ── Application stack ─────────────────────────────────────────────────────────
module "app_stack" {
  source = "../../../../../../stacks/application-stack"

  root_client = "devops"
  client_name = "devops"
  product     = "PRODA"
  service     = "auth-api-service"
  environment = "dev"
  aws_region  = "us-east-1"

  # Networking — pulled from 01-network remote state
  vpc_id                 = data.terraform_remote_state.network.outputs.vpc_id
  private_subnet_ids     = data.terraform_remote_state.network.outputs.private_db_subnet_ids
  private_app_subnet_ids = data.terraform_remote_state.network.outputs.private_app_subnet_ids
  public_subnet_ids      = data.terraform_remote_state.network.outputs.public_subnet_ids
  eks_security_group_ids = compact([
    try(data.terraform_remote_state.network.outputs.eks_nodes_security_group_id, ""),
    try(data.terraform_remote_state.network.outputs.eks_cluster_security_group_id, ""),
  ])

  # Resource flags and per-resource config
  create_dns               = false
  create_rds_mysql         = true
  rds_mysql_name           = "devops-dev-mysql"
  rds_mysql_db_name        = "appdb"
  rds_mysql_username       = "dbadmin"
  rds_mysql_instance_class = "db.t3.medium"
  create_elasticache       = true
  elasticache_name         = "devops-dev-elasticache"
  elasticache_node_type    = "cache.t3.medium"
  create_s3                = true
  s3_bucket_name           = "devops-dev-proda-backend-s3"
  # rds_mysql_password intentionally NOT set here: the stack generates one with random_password.
  # If you must supply one, pass it via TF_VAR_rds_mysql_password or a Secrets Manager lookup, never in git.
}

output "stack_outputs" {
  value     = module.app_stack
  sensitive = true
}

