terraform {
  backend "s3" {
    bucket       = "example-tf-state-123456789012-us-east-1"
    key          = "launchpad/environments/devops/devops/proda/auth-api-service/dev/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
