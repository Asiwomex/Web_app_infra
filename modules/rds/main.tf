terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# ─── Random DB Password → Secrets Manager ────────────────────────────────────

resource "random_password" "db" {
  length           = 20
  special          = false # avoid characters that break PostgreSQL connection strings
  override_special = ""
}

resource "aws_secretsmanager_secret" "db" {
  name = "${var.project_name}/${var.environment}/db-credentials"

  # prod: 30-day recovery window; non-prod: immediate deletion for fast teardown
  recovery_window_in_days = var.environment == "prod" ? 30 : 0

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-db-secret"
  })
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
    engine   = "postgres"
    host     = aws_db_instance.primary.address
    port     = 5432
    dbname   = var.db_name
    ro_host  = aws_db_instance.replica.address
  })
}

# ─── DB Subnet Group ──────────────────────────────────────────────────────────

resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-${var.environment}-db-subnet-group"
  description = "DB subnet group for ${var.project_name} ${var.environment}"
  subnet_ids  = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  })
}

# ─── Parameter Group ─────────────────────────────────────────────────────────

resource "aws_db_parameter_group" "main" {
  name_prefix = "${var.project_name}-${var.environment}-pg16-"
  family      = "postgres16"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = var.environment == "prod" ? "1000" : "500"
  }

  parameter {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements"
    apply_method = "pending-reboot"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-pg16"
  })
}

# ─── Primary RDS Instance (AZ1) ───────────────────────────────────────────────

resource "aws_db_instance" "primary" {
  identifier = "${var.project_name}-${var.environment}-primary"

  engine                = "postgres"
  engine_version        = "16.3"
  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]
  parameter_group_name   = aws_db_parameter_group.main.name

  availability_zone   = var.primary_az
  multi_az            = false # replica is managed explicitly below
  publicly_accessible = false

  backup_retention_period = var.environment == "prod" ? 14 : 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"
  copy_tags_to_snapshot   = true

  deletion_protection       = var.environment == "prod" ? true : false
  skip_final_snapshot       = var.environment == "prod" ? false : true
  final_snapshot_identifier = var.environment == "prod" ? "${var.project_name}-${var.environment}-final" : null

  performance_insights_enabled          = var.environment == "prod" ? true : false
  performance_insights_retention_period = var.environment == "prod" ? 7 : null

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  auto_minor_version_upgrade = true
  apply_immediately          = var.environment != "prod"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-primary"
    Role = "Primary"
  })
}

# ─── Read Replica (AZ2) ───────────────────────────────────────────────────────

resource "aws_db_instance" "replica" {
  identifier = "${var.project_name}-${var.environment}-replica"

  # Replica inherits engine, version, db_name, username, password from source
  replicate_source_db = aws_db_instance.primary.identifier
  instance_class      = var.replica_instance_class
  availability_zone   = var.replica_az

  vpc_security_group_ids = [var.security_group_id]

  publicly_accessible = false
  skip_final_snapshot = true
  storage_encrypted   = true

  auto_minor_version_upgrade = true
  apply_immediately          = var.environment != "prod"

  performance_insights_enabled = var.environment == "prod" ? true : false

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-replica"
    Role = "ReadReplica"
  })
}
