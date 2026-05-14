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
      Environment = "Demo"
      ManagedBy   = "Terraform"
    }
  }
}

locals {
  environment = "staging"
  tags = {
    Environment = "Demo"
    Project     = var.project_name
  }
}

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
  tags                    = local.tags
}

module "security_groups" {
  source = "../../modules/security_groups"

  project_name = var.project_name
  environment  = local.environment
  vpc_id       = module.vpc.vpc_id
  app_port     = var.app_port
  tags         = local.tags
}

module "s3" {
  source = "../../modules/s3"

  project_name = var.project_name
  environment  = local.environment
  tags         = local.tags
}

module "alb" {
  source = "../../modules/alb"

  project_name               = var.project_name
  environment                = local.environment
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  alb_sg_id                  = module.security_groups.alb_sg_id
  app_port                   = var.app_port
  domain_name                = var.alb_domain_name
  health_check_path          = var.health_check_path
  enable_deletion_protection = false
  access_logs_bucket         = module.s3.bucket_name
  tags                       = local.tags
}

module "ec2_app" {
  source = "../../modules/ec2_app"

  project_name      = var.project_name
  environment       = local.environment
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

module "rds" {
  source = "../../modules/rds"

  project_name           = var.project_name
  environment            = local.environment
  subnet_ids             = module.vpc.private_subnet_ids
  security_group_id      = module.security_groups.rds_sg_id
  db_name                = var.db_name
  db_username            = var.db_username
  instance_class         = var.db_instance_class
  replica_instance_class = var.db_replica_instance_class
  allocated_storage      = var.db_allocated_storage
  max_allocated_storage  = var.db_max_allocated_storage
  primary_az             = "${var.aws_region}a"
  replica_az             = "${var.aws_region}b"
  tags                   = local.tags
}

module "waf" {
  source = "../../modules/waf"

  project_name       = var.project_name
  environment        = local.environment
  aws_region         = var.aws_region
  alb_arn            = module.alb.alb_arn
  rate_limit         = var.waf_rate_limit
  log_retention_days = 30
  tags               = local.tags
}

module "cognito" {
  source = "../../modules/cognito"

  project_name  = var.project_name
  environment   = local.environment
  callback_urls = var.cognito_callback_urls
  logout_urls   = var.cognito_logout_urls
  tags          = local.tags
}

module "monitoring" {
  source = "../../modules/monitoring"

  project_name            = var.project_name
  environment             = local.environment
  alert_emails            = var.alert_emails
  rds_primary_id          = module.rds.primary_identifier
  rds_replica_id          = module.rds.replica_identifier
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  asg_name                = module.ec2_app.asg_name
  tags                    = local.tags
}
