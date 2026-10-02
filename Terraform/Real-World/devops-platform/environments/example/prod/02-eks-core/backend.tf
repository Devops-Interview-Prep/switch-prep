terraform {
  backend "s3" {
    bucket       = "example-tf-state-123456789012-us-east-1"
    key          = "launchpad/environments/example/prod/02-eks-core/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
