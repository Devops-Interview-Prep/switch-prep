terraform {
  backend "s3" {
    bucket       = "example-tf-state-123456789012-us-east-1"
    key          = "launchpad/environments/clienta/dev/03-eks-platform/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}