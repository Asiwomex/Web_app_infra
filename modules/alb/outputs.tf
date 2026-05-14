output "alb_arn" {
  value = aws_lb.main.arn
}

output "alb_arn_suffix" {
  description = "ALB ARN suffix — needed for CloudWatch metric dimensions"
  value       = aws_lb.main.arn_suffix
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "alb_zone_id" {
  value = aws_lb.main.zone_id
}

output "target_group_arn" {
  value = aws_lb_target_group.app.arn
}

output "target_group_arn_suffix" {
  description = "Target group ARN suffix — needed for CloudWatch metric dimensions"
  value       = aws_lb_target_group.app.arn_suffix
}

output "certificate_arn" {
  value = aws_acm_certificate_validation.main.certificate_arn
}

output "https_listener_arn" {
  value = aws_lb_listener.https.arn
}
