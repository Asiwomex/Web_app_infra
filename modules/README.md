# Modules

Reusable building blocks. Each environment in `../environments/*` calls all of these.

## Module map

| Module             | What it creates                                                      |
|--------------------|----------------------------------------------------------------------|
| `vpc/`             | VPC, IGW, NAT GW, 2 public + 2 private subnets, route tables, flow logs |
| `security_groups/` | ALB / app / RDS security groups (least-privilege; admin access via SSM) |
| `alb/`             | ALB, target group, HTTP→HTTPS redirect, ACM cert with Route 53 DNS validation |
| `waf/`             | WAFv2 web ACL with 5 rules (Common, Bad Inputs, SQLi, IP Rep, rate limit), CloudWatch logging |
| `ec2_app/`         | Ubuntu 22.04 EC2, IAM role with SSM + CloudWatch + Secrets Manager read, IMDSv2 |
| `rds/`             | Postgres 16 primary + read replica + Secrets Manager-managed credentials |
| `s3/`              | Versioned + encrypted bucket, public-access blocked, TLS-only, lifecycle policy |
| `cognito/`         | User pool, web client (OAuth2 PKCE), hosted domain                   |
| `route53/`         | ALB alias record (zone created in `bootstrap/`)                      |
| `monitoring/`      | SNS topic, 10 CloudWatch alarms (RDS, ALB, ASG, EC2 memory/disk)    |

## Dependency graph

```
vpc ── security_groups ─┐
                         ├─ ec2_app ── alb ── waf
                         │              │
                         ├─ rds          └── route53 (alb)
                         │
s3 (independent)    cognito (independent)    monitoring (independent)
```

## Conventions

- Every module takes `project_name` and `environment` for naming
- Every module accepts a `tags` map and merges it with module-specific tags
- Module-specific names follow `${project_name}-${environment}-<role>` to avoid cross-env collisions
- All sensitive defaults (deletion protection, MFA, Performance Insights) are conditional on `var.environment == "prod"` — overridable per env
- No module reaches outside its scope: outputs are passed in, results are passed out, no `data` lookups across modules

## Calling a module

Always pin the source path; variables are documented in each module's `variables.tf`.

```hcl
module "vpc" {
  source = "../../modules/vpc"

  project_name            = "insight-edge"
  environment             = "dev"
  aws_region              = "us-east-1"
  vpc_cidr                = "10.0.0.0/22"
  public_subnet_az1_cidr  = "10.0.0.0/25"
  public_subnet_az2_cidr  = "10.0.0.128/25"
  private_subnet_az1_cidr = "10.0.1.0/24"
  private_subnet_az2_cidr = "10.0.2.0/24"
  tags                    = { Environment = "Development" }
}
```

## Editing a module

Changes ripple to every environment. To roll out cautiously:

1. Make the change
2. `terraform plan` in **dev** — review impact
3. Apply in dev, verify
4. Plan and apply in staging
5. Plan and apply in prod (only if staging is healthy for >24h)

## Adding a new module

Follow the existing pattern: `main.tf`, `variables.tf`, `outputs.tf`. Wire it into each environment's `main.tf`. Don't introduce cross-module `data` lookups — pass values in via inputs.
