data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# ─── ALB Alias Record ─────────────────────────────────────────────────────────

resource "aws_route53_record" "alb" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.alb_dns_subdomain
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
