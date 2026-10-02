output "instance_ids" {
  description = "EC2 instance IDs (one per instance_count)"
  value       = aws_instance.ra[*].id
}

output "private_ips" {
  description = "Private IPs of the RA EC2 instances"
  value       = aws_instance.ra[*].private_ip
}

output "security_group_id" {
  description = "Security group ID attached to the RA instance"
  value       = aws_security_group.ra.id
}

output "iam_role_arn" {
  description = "IAM role ARN for the RA instance"
  value       = aws_iam_role.ra.arn
}

output "iam_instance_profile_name" {
  description = "IAM instance profile name"
  value       = aws_iam_instance_profile.ra.name
}
