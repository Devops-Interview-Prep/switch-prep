output "endpoint" {
  description = "RDS MySQL endpoint address"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "RDS MySQL port"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.this.db_name
}

output "instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.this.identifier
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.this.id
}
