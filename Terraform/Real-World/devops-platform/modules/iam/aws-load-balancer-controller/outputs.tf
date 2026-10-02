output "role_name" {
  description = "AWS Load Balancer Controller IAM role name."
  value       = aws_iam_role.this.name
}

output "role_arn" {
  description = "AWS Load Balancer Controller IAM role ARN."
  value       = aws_iam_role.this.arn
}

output "policy_arn" {
  description = "AWS Load Balancer Controller IAM policy ARN."
  value       = aws_iam_policy.this.arn
}