output "internet_gateway_id" {
  description = "ID of the Internet Gateway."
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways."
  value       = aws_nat_gateway.this[*].id
}

output "nat_eip_ids" {
  description = "IDs of the NAT Elastic IPs."
  value       = aws_eip.nat[*].id
}

output "public_route_table_id" {
  description = "ID of the public route table."
  value       = aws_route_table.public.id
}

output "private_app_route_table_ids" {
  description = "IDs of private application route tables."
  value       = aws_route_table.private_app[*].id
}

output "private_db_route_table_ids" {
  description = "IDs of private DB route tables."
  value       = aws_route_table.private_db[*].id
}

output "nat_gateway_mode" {
  description = "NAT Gateway mode used by the module."
  value       = var.enable_nat_gateway ? var.nat_gateway_mode : "disabled"
}