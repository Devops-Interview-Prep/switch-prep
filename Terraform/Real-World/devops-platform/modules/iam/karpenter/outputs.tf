output "controller_role_name" {
  description = "Karpenter controller IAM role name."
  value       = aws_iam_role.controller.name
}

output "controller_role_arn" {
  description = "Karpenter controller IAM role ARN."
  value       = aws_iam_role.controller.arn
}

output "controller_policy_arn" {
  description = "Karpenter controller IAM policy ARN."
  value       = aws_iam_policy.controller.arn
}