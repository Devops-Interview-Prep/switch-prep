output "instance_id" {
  description = "EC2 instance ID of the Solr node"
  value       = aws_instance.solr.id
}

output "private_ip" {
  description = "Private IP address of the Solr node"
  value       = aws_instance.solr.private_ip
}

output "solr_url" {
  description = "Full Solr base URL"
  value       = "http://${aws_instance.solr.private_ip}:${var.solr_port}/solr/"
}

output "security_group_id" {
  description = "Security group ID attached to the Solr node"
  value       = aws_security_group.solr.id
}

output "iam_role_arn" {
  description = "IAM role ARN for the Solr instance"
  value       = aws_iam_role.solr.arn
}
