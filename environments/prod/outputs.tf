output "vpc_id" {
  value = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "Add a CNAME record on Namecheap: 'prod' -> this value"
  value       = module.alb.alb_dns_name
}

output "acm_validation_cname" {
  description = "Add this CNAME record on Namecheap to validate the HTTPS certificate"
  value       = module.alb.acm_validation_cname
}

output "asg_name" {
  description = "ASG name — use with 'aws ssm start-session' for shell access"
  value       = module.ec2_app.asg_name
}

output "db_primary_endpoint" {
  value     = module.rds.primary_endpoint
  sensitive = true
}

output "db_replica_endpoint" {
  value     = module.rds.replica_endpoint
  sensitive = true
}

output "db_secret_arn" {
  description = "Retrieve DB credentials: aws secretsmanager get-secret-value --secret-id <arn>"
  value       = module.rds.db_secret_arn
}

output "cognito_user_pool_id" {
  value = module.cognito.user_pool_id
}

output "cognito_client_id" {
  value = module.cognito.user_pool_client_id
}

output "s3_bucket_name" {
  value = module.s3.bucket_name
}

output "waf_web_acl_arn" {
  value = module.waf.web_acl_arn
}

output "alerts_topic_arn" {
  description = "SNS topic — confirm email subscriptions in your inbox"
  value       = module.monitoring.sns_topic_arn
}
