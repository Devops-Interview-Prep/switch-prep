variable "aws_region" {
  description = "AWS region for the state bucket and lock table"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS named profile to use"
  type        = string
  default     = "example-prod"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket to hold Terraform state files"
  type        = string
  default     = "example-tf-state"
}

variable "lock_table_name" {
  description = "Name of the DynamoDB table used for state locking"
  type        = string
  default     = "example-tf-lock"
}
