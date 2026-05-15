# ── Staging (Demo) Environment ─────────────────────────────────────────────────

aws_region   = "us-east-1"
project_name = "insight-edge"
domain_name  = "insight-edgecs.com"

key_pair_name = "infratest"

# VPC  (10.0.4.0/22)
vpc_cidr                = "10.0.4.0/22"
public_subnet_az1_cidr  = "10.0.4.0/25"
public_subnet_az2_cidr  = "10.0.4.128/25"
private_subnet_az1_cidr = "10.0.5.0/24"
private_subnet_az2_cidr = "10.0.6.0/24"

# Compute  (HA: 2 instances across AZ1+AZ2; scales to 4 on load)
app_instance_type    = "t3.medium"
app_root_volume_size = 30
app_port             = 8080
asg_min_size         = 2
asg_max_size         = 4
asg_desired_capacity = 2
# Database
db_name                   = "appdb"
db_username               = "dbadmin"
db_instance_class         = "db.t3.small"
db_replica_instance_class = "db.t3.small"
db_allocated_storage      = 20
db_max_allocated_storage  = 100

# ALB
alb_domain_name   = "stage.insight-edgecs.com"
health_check_path = "/health"

# WAF
waf_rate_limit = 2000

# Cognito
cognito_callback_urls = ["https://stage.insight-edgecs.com/callback"]
cognito_logout_urls   = ["https://stage.insight-edgecs.com/logout"]

# Alerting
alert_emails = ["gabelorm@insight-edgecs.com"]
