output "new_public_subnet_ids" {
  description = "IDs of newly created public subnets"
  value       = [for s in aws_subnet.public_new : s.id]
}

output "new_private_app_subnet_ids" {
  description = "IDs of newly created private-app subnets"
  value       = [for s in aws_subnet.private_app_new : s.id]
}

output "new_private_db_subnet_ids" {
  description = "IDs of newly created private-db subnets"
  value       = [for s in aws_subnet.private_db_new : s.id]
}

output "new_nat_gateway_ids" {
  description = "IDs of newly created NAT gateways"
  value       = [for n in aws_nat_gateway.new : n.id]
}

output "internet_gateway_id" {
  description = "ID of the IGW (new or empty if not created)"
  value       = length(aws_internet_gateway.new) > 0 ? aws_internet_gateway.new[0].id : ""
}
