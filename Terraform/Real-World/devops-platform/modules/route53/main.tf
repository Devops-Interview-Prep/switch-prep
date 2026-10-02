terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

# Alias A record pointing to an ALB
resource "aws_route53_record" "alias" {
  count   = var.record_type == "ALIAS" ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = "${var.subdomain}.${var.hosted_zone}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# CNAME record (fallback or non-ALB targets)
resource "aws_route53_record" "cname" {
  count   = var.record_type == "CNAME" ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = "${var.subdomain}.${var.hosted_zone}"
  type    = "CNAME"
  ttl     = var.ttl
  records = [var.cname_target]
}
