# Environments

One folder per environment. They share the modules in `../modules/` but each has its own VPC, state file, and resources.

## Pre-flight checklist

Before `terraform apply` in any environment:

- [ ] Bootstrap stack has been applied (see `../bootstrap/README.md`)
- [ ] Domain NS records updated at registrar
- [ ] EC2 key pair exists in the target region
- [ ] `backend.tf` — `<ACCOUNT_ID>` placeholder replaced with real account ID
- [ ] `terraform.tfvars` — `route53_zone_id` and `key_pair_name` filled in

## Apply order

```bash
cd dev      && terraform init && terraform plan && terraform apply
cd staging  && terraform init && terraform plan && terraform apply
cd prod     && terraform init && terraform plan && terraform apply
```

Order matters only because you'll catch most issues in dev before touching prod. There's no shared state between them.

## What's different per environment

| Setting                   | dev            | staging        | prod           |
|---------------------------|----------------|----------------|----------------|
| VPC CIDR                  | 10.0.0.0/22    | 10.0.4.0/22    | 10.0.8.0/22    |
| App instance              | t3.small       | t3.medium      | t3.large       |
| RDS primary/replica       | db.t3.micro    | db.t3.small    | db.t3.medium   |
| RDS allocated storage     | 20 GB          | 20 GB          | 50 GB          |
| RDS backup retention      | 7 days         | 7 days         | 14 days        |
| ALB deletion protection   | off            | off            | on             |
| RDS deletion protection   | off            | off            | on             |
| Cognito MFA               | off            | off            | optional       |
| Cognito advanced security | off            | off            | enforced       |
| WAF rate limit (req/5min) | 2000           | 2000           | 1000           |
| WAF log retention         | 30 days        | 30 days        | 90 days        |
| Performance Insights      | off            | off            | on             |
| `apply_immediately` (RDS) | true           | true           | false          |
| Final DB snapshot         | skipped        | skipped        | required       |

Everything else (security groups, encryption, IMDSv2, etc.) is identical across environments.

## Outputs

After apply, useful values:

```bash
terraform output alb_url               # https://dev.insight-edgecs.com
terraform output asg_name              # use with: aws ssm start-session --target <instance-id>
terraform output db_secret_arn         # for fetching DB creds from Secrets Manager
terraform output cognito_user_pool_id
```

## Tearing down

```bash
terraform destroy
```

For prod, you'll first need to:
1. Set `enable_deletion_protection = false` on the ALB module call
2. Set `deletion_protection = false` in the RDS resource (or override the conditional)
3. Apply
4. Then destroy

Note: the Route 53 records and ACM certificate are deleted with the env. The hosted zone in `bootstrap/` survives.
