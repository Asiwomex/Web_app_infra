# ── Nonprod Environment (dev + staging on shared infrastructure) ──────────────
# One VPC, one ALB, one RDS — replaces running dev and staging separately.
# Cost saving vs separate dev+staging: ~$2.76/24hrs (1x NAT GW, ALB, RDS, WAF removed).
# NOTE: Do NOT deploy this while environments/dev or environments/staging are active —
# they share the same sub-environment names (dev, staging) in the same AWS account.

aws_region   = "us-east-1"
project_name = "insight-edge"
domain_name  = "insight-edgecs.com"

key_pair_name = "infratest"

# VPC (10.0.12.0/22 — does not overlap dev/staging/prod CIDRs)
vpc_cidr                = "10.0.12.0/22"
public_subnet_az1_cidr  = "10.0.12.0/25"
public_subnet_az2_cidr  = "10.0.12.128/25"
private_subnet_az1_cidr = "10.0.13.0/24"
private_subnet_az2_cidr = "10.0.14.0/24"

# Compute — one instance per sub-env (scale to 2 on load)
app_instance_type    = "t3.small"
app_root_volume_size = 20
app_port             = 8080
asg_min_size         = 1
asg_max_size         = 2
asg_desired_capacity = 1

# Database — shared primary only, no replica
db_name                  = "appdb"
db_username              = "dbadmin"
db_instance_class        = "db.t3.micro"
db_allocated_storage     = 20
db_max_allocated_storage = 50

health_check_path = "/health"

alert_emails = ["gabelorm@insight-edgecs.com"]
