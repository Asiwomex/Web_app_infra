# Environments

Two folders — `nonprod` and `prod`. They share the modules in `../modules/` but each has its own VPC, state file, and resources.

## nonprod

Runs dev and staging on **shared infrastructure**: one VPC, one NAT Gateway, one ALB with host-based routing, one RDS primary. No WAF, no read replica.

- `dev.insight-edgecs.com` → dev ASG (default ALB action)
- `stage.insight-edgecs.com` → staging ASG (ALB listener rule, priority 10)
- ACM certificate covers both domains (Subject Alternative Name)

## prod

Fully isolated VPC, dual NAT Gateways, RDS primary + read replica, WAF enabled, deletion protection on ALB and RDS.

## Pre-flight checklist

Before `terraform apply` in any environment:

- [ ] Bootstrap stack has been applied (see `../bootstrap/README.md`)
- [ ] `insight-edgecs.com` DNS managed in Cloudflare (nameservers set at registrar)
- [ ] EC2 key pair exists in the target region (`infratest`)
- [ ] Old ACM validation CNAMEs deleted from Cloudflare (hashes change on every new cert)

## Apply order

```powershell
cd nonprod  && terraform init && terraform apply
cd prod     && terraform init && terraform apply
```

No shared state between them — order does not matter technically, but validate nonprod first.

## What's different per environment

| Setting                   | nonprod (dev+stage)    | prod           |
|---------------------------|------------------------|----------------|
| VPC CIDR                  | 10.0.12.0/22           | 10.0.8.0/22    |
| NAT Gateways              | 1 (single AZ)          | 2 (per AZ)     |
| App instance              | t3.small               | t3.large       |
| ASG min / desired         | 1 / 1 per sub-env      | 2 / 2          |
| RDS primary               | db.t3.micro            | db.t3.medium   |
| RDS read replica          | none                   | db.t3.medium   |
| RDS backup retention      | 7 days                 | 14 days        |
| ALB deletion protection   | off                    | on             |
| RDS deletion protection   | off                    | on             |
| WAF                       | off                    | on (rate 1000) |
| Performance Insights      | off                    | on             |
| Final DB snapshot         | skipped                | required       |

## Useful outputs after apply

```powershell
terraform output alb_dns_name       # CNAME target for Cloudflare
terraform output acm_validation_cnames  # CNAMEs to add to Cloudflare during apply
terraform output dev_asg_name       # nonprod only
terraform output staging_asg_name   # nonprod only
```

## Tearing down

```powershell
terraform destroy
```

For prod, first disable deletion protection:
1. Disable ALB deletion protection via AWS CLI (see RUNBOOK.md Troubleshooting)
2. Wait for RDS to reach `available` state
3. Run `terraform destroy`
