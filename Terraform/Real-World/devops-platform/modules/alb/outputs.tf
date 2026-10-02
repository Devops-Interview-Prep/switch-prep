output "alb_arn" { value = aws_lb.this.arn }
output "alb_dns_name" { value = aws_lb.this.dns_name }
output "alb_zone_id" { value = aws_lb.this.zone_id }
output "alb_name" { value = aws_lb.this.name }
output "security_group_id" { value = aws_security_group.alb.id }

output "app_tg_arn" { value = aws_lb_target_group.app.arn }
output "control_plane_tg_arn" { value = aws_lb_target_group.control_plane.arn }
output "orchestrator_tg_arn" { value = aws_lb_target_group.orchestrator.arn }
