output "vpc_id" {
  value = module.vpc.vpc_id
}

output "alb_url" {
  description = "Application URL"
  value       = "https://${module.route53.alb_fqdn}"
}

output "asg_name" {
  description = "ASG name — use with 'aws ssm start-session' for shell access"
  value       = module.ec2_app.asg_name
}

output "db_primary_endpoint" {
  value = module.rds.primary_endpoint
}

output "db_replica_endpoint" {
  value = module.rds.replica_endpoint
}

output "db_secret_arn" {
  description = "Secrets Manager ARN for database credentials"
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

output "alerts_topic_arn" {
  description = "SNS topic — confirm email subscriptions in your inbox"
  value       = module.monitoring.sns_topic_arn
}
