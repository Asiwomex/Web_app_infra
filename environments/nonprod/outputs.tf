output "alb_dns_name" {
  description = "ALB DNS name — add as CNAME for both dev and stage subdomains in Cloudflare"
  value       = module.alb.alb_dns_name
}

output "dev_subdomain" {
  value = "dev.insight-edgecs.com → ${module.alb.alb_dns_name}"
}

output "staging_subdomain" {
  value = "stage.insight-edgecs.com → ${module.alb.alb_dns_name}"
}

output "acm_validation_cnames" {
  description = "Add ALL of these CNAME records to Cloudflare before/during apply to validate ACM cert"
  value       = module.alb.acm_validation_cname
}

output "rds_secret_arn" {
  value = module.rds.db_secret_arn
}

output "dev_asg_name" {
  value = module.ec2_dev.asg_name
}

output "staging_asg_name" {
  value = module.ec2_staging.asg_name
}
