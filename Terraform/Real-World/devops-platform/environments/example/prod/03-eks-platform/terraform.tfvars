aws_region = "us-east-1"

remote_state_bucket = "example-tf-state-123456789012-us-east-1"
eks_core_state_key  = "launchpad/environments/example/prod/02-eks-core/terraform.tfstate"
network_state_key   = "launchpad/environments/example/prod/01-network/terraform.tfstate"

client      = "example"
environment = "prod"
name_prefix = "example-prod"

cluster_name = "example-prod-eks"

tags = {
  Project   = "devops-launchpad"
  Owner     = "devops"
  Terraform = "true"
}
