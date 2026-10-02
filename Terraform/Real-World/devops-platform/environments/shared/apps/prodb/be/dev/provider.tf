provider "aws" {
  region  = "us-east-1"
  profile = "example-terraform" # named profile; CI should use an assumed role instead
}
