output "fqdn" {
  value = var.record_type == "ALIAS" ? aws_route53_record.alias[0].fqdn : aws_route53_record.cname[0].fqdn
}
