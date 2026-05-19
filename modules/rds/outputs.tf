output "primary_endpoint" {
  value = aws_db_instance.primary.endpoint
}

output "primary_address" {
  value = aws_db_instance.primary.address
}

output "replica_endpoint" {
  value = var.create_replica ? aws_db_instance.replica[0].endpoint : ""
}

output "replica_address" {
  value = var.create_replica ? aws_db_instance.replica[0].address : ""
}

output "db_secret_arn" {
  value = aws_secretsmanager_secret.db.arn
}

output "db_secret_name" {
  value = aws_secretsmanager_secret.db.name
}

output "db_name" {
  value = var.db_name
}

output "primary_identifier" {
  value = aws_db_instance.primary.identifier
}

output "replica_identifier" {
  value = var.create_replica ? aws_db_instance.replica[0].identifier : ""
}
