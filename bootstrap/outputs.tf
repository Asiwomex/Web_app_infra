output "state_bucket_name" {
  description = "S3 bucket name for Terraform state — use in each environment backend.tf"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "route53_zone_id" {
  description = "Route 53 hosted zone ID — set as route53_zone_id in each environment tfvars"
  value       = aws_route53_zone.main.zone_id
}

output "route53_name_servers" {
  description = "NS records to configure at your domain registrar"
  value       = aws_route53_zone.main.name_servers
}

output "aws_account_id" {
  description = "AWS account ID — needed for backend bucket name"
  value       = data.aws_caller_identity.current.account_id
}

output "cloudtrail_arn" {
  value = aws_cloudtrail.main.arn
}

output "cloudtrail_bucket" {
  value = aws_s3_bucket.cloudtrail.bucket
}

output "guardduty_detector_id" {
  value = aws_guardduty_detector.main.id
}
