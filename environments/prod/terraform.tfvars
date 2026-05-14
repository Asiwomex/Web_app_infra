# ── Production Environment ─────────────────────────────────────────────────────
# WARNING: deletion_protection=true on ALB and RDS. Plan reviews mandatory.

aws_region   = "us-east-1"
project_name = "insight-edge"
domain_name  = "theboateng.me"

key_pair_name = "infratest"

# VPC  (10.0.8.0/22)
vpc_cidr                = "10.0.8.0/22"
public_subnet_az1_cidr  = "10.0.8.0/25"
public_subnet_az2_cidr  = "10.0.8.128/25"
private_subnet_az1_cidr = "10.0.9.0/24"
private_subnet_az2_cidr = "10.0.10.0/24"

# Compute  (HA: min 2 instances across AZ1+AZ2; scales to 6 on load)
app_instance_type    = "t3.large"
app_root_volume_size = 50
app_port             = 8080
asg_min_size         = 2
asg_max_size         = 6
asg_desired_capacity = 2
# Database
db_name                   = "appdb"
db_username               = "dbadmin"
db_instance_class         = "db.t3.medium"
db_replica_instance_class = "db.t3.medium"
db_allocated_storage      = 50
db_max_allocated_storage  = 500

# ALB
alb_domain_name   = "prod.theboateng.me"
health_check_path = "/health"

# WAF — tighter rate limit for prod
waf_rate_limit = 1000

# Cognito
cognito_callback_urls = ["https://prod.theboateng.me/callback"]
cognito_logout_urls   = ["https://prod.theboateng.me/logout"]

# Alerting — REQUIRED for prod. Add at least one on-call email/distribution list.
alert_emails = ["gabelorm@insight-edgecs.com"]
