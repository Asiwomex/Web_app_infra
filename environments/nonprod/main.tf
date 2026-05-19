terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "NonProd"
      ManagedBy   = "Terraform"
    }
  }
}

locals {
  environment = "nonprod"
  tags = {
    Environment = "NonProd"
    Project     = var.project_name
  }
}

# ─── VPC (shared — one NAT Gateway) ──────────────────────────────────────────

module "vpc" {
  source = "../../modules/vpc"

  project_name            = var.project_name
  environment             = local.environment
  aws_region              = var.aws_region
  vpc_cidr                = var.vpc_cidr
  public_subnet_az1_cidr  = var.public_subnet_az1_cidr
  public_subnet_az2_cidr  = var.public_subnet_az2_cidr
  private_subnet_az1_cidr = var.private_subnet_az1_cidr
  private_subnet_az2_cidr = var.private_subnet_az2_cidr
  single_nat_gateway      = true
  tags                    = local.tags
}

# ─── Security Groups (shared — both apps run on the same port) ────────────────

module "security_groups" {
  source = "../../modules/security_groups"

  project_name = var.project_name
  environment  = local.environment
  vpc_id       = module.vpc.vpc_id
  app_port     = var.app_port
  tags         = local.tags
}

# ─── S3 (ALB access logs) ─────────────────────────────────────────────────────

module "s3" {
  source = "../../modules/s3"

  project_name = var.project_name
  environment  = local.environment
  tags         = local.tags
}

# ─── ALB — one ALB routing two subdomains via host-based listener rules ───────
# dev.insight-edgecs.com  → default action → dev target group
# stage.insight-edgecs.com → listener rule priority 10 → staging target group
# ACM cert covers both domains (SAN).

module "alb" {
  source = "../../modules/alb"

  project_name               = var.project_name
  environment                = local.environment
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  alb_sg_id                  = module.security_groups.alb_sg_id
  app_port                   = var.app_port
  domain_name                = "dev.insight-edgecs.com"
  subject_alternative_names  = ["stage.insight-edgecs.com"]
  health_check_path          = var.health_check_path
  enable_deletion_protection = false
  access_logs_bucket         = module.s3.bucket_name
  tags                       = local.tags

  extra_routes = [
    {
      name        = "staging"
      host_header = "stage.insight-edgecs.com"
      port        = var.app_port
    }
  ]
}

# ─── Dev App ASG ──────────────────────────────────────────────────────────────

module "ec2_dev" {
  source = "../../modules/ec2_app"

  project_name      = var.project_name
  environment       = "dev"
  aws_region        = var.aws_region
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_id = module.security_groups.app_sg_id
  target_group_arn  = module.alb.target_group_arn
  instance_type     = var.app_instance_type
  key_pair_name     = var.key_pair_name
  root_volume_size  = var.app_root_volume_size
  min_size          = var.asg_min_size
  max_size          = var.asg_max_size
  desired_capacity  = var.asg_desired_capacity
  tags              = local.tags
}

# ─── Staging App ASG ──────────────────────────────────────────────────────────

module "ec2_staging" {
  source = "../../modules/ec2_app"

  project_name      = var.project_name
  environment       = "staging"
  aws_region        = var.aws_region
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_id = module.security_groups.app_sg_id
  target_group_arn  = module.alb.extra_target_group_arns["staging"]
  instance_type     = var.app_instance_type
  key_pair_name     = var.key_pair_name
  root_volume_size  = var.app_root_volume_size
  min_size          = var.asg_min_size
  max_size          = var.asg_max_size
  desired_capacity  = var.asg_desired_capacity
  tags              = local.tags
}

# ─── RDS (shared primary, no replica) ────────────────────────────────────────

module "rds" {
  source = "../../modules/rds"

  project_name           = var.project_name
  environment            = local.environment
  subnet_ids             = module.vpc.private_subnet_ids
  security_group_id      = module.security_groups.rds_sg_id
  db_name                = var.db_name
  db_username            = var.db_username
  instance_class         = var.db_instance_class
  replica_instance_class = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  max_allocated_storage  = var.db_max_allocated_storage
  primary_az             = "${var.aws_region}a"
  replica_az             = "${var.aws_region}b"
  create_replica         = false
  tags                   = local.tags
}

# ─── Cognito ─────────────────────────────────────────────────────────────────

module "cognito_dev" {
  source = "../../modules/cognito"

  project_name  = var.project_name
  environment   = "dev"
  callback_urls = ["https://dev.insight-edgecs.com/callback"]
  logout_urls   = ["https://dev.insight-edgecs.com/logout"]
  tags          = local.tags
}

module "cognito_staging" {
  source = "../../modules/cognito"

  project_name  = var.project_name
  environment   = "staging"
  callback_urls = ["https://stage.insight-edgecs.com/callback"]
  logout_urls   = ["https://stage.insight-edgecs.com/logout"]
  tags          = local.tags
}

# ─── Monitoring ───────────────────────────────────────────────────────────────

module "monitoring_dev" {
  source = "../../modules/monitoring"

  project_name            = var.project_name
  environment             = "dev"
  alert_emails            = var.alert_emails
  rds_primary_id          = module.rds.primary_identifier
  rds_replica_id          = ""
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  asg_name                = module.ec2_dev.asg_name
  tags                    = local.tags
}

module "monitoring_staging" {
  source = "../../modules/monitoring"

  project_name            = var.project_name
  environment             = "staging"
  alert_emails            = var.alert_emails
  rds_primary_id          = module.rds.primary_identifier
  rds_replica_id          = ""
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.extra_target_group_arn_suffixes["staging"]
  asg_name                = module.ec2_staging.asg_name
  tags                    = local.tags
}
