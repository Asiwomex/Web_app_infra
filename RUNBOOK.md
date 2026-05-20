# Deployment Runbook — Full Redeploy from Scratch

Use this after a `terraform destroy` to bring all environments back up.
Domain: `insight-edgecs.com` | AWS Account: `310688446551` | Region: `us-east-1`

**Environments:**
- `environments/nonprod` — dev + staging on shared infrastructure (one VPC, one ALB, one RDS)
- `environments/prod` — production, fully isolated

---

## Prerequisites

- AWS CLI configured (`aws sts get-caller-identity` returns your account ID)
- Terraform installed (`terraform version` returns 1.9.0+)
- Bootstrap already applied — S3 state bucket exists (do NOT re-run bootstrap)
- `insight-edgecs.com` DNS managed in Cloudflare

---

## Before You Start — Clean Up Leftover AWS Resources

After `terraform destroy`, two types of resources persist and will cause errors on re-apply:

1. **CloudWatch Log Groups** — not deleted by Terraform destroy; must be imported into new state
2. **Secrets Manager Secrets** — go into a 7-day scheduled deletion queue; must be restored before Terraform can recreate them

Also, **ACM validation CNAME hashes change on every new deployment** — delete the old `_<hash>.dev`, `_<hash>.stage`, `_<hash>.prod` records from Cloudflare before applying.

### Restore Secrets Manager secrets (run once before any apply)

```powershell
aws secretsmanager restore-secret --secret-id insight-edge/nonprod/db-credentials --region us-east-1
aws secretsmanager restore-secret --secret-id insight-edge/prod/db-credentials --region us-east-1
```

> If any command returns `ResourceNotFoundException`, the secret was fully deleted (past the 7-day window) — skip it, Terraform will create it fresh.

---

## Step 1 — Deploy Nonprod (dev + staging on shared infra)

### Step 1a — Pre-apply imports

Run these before `terraform apply` to prevent known errors:

```powershell
cd environments/nonprod
terraform init

# Import CloudWatch log group if it still exists from previous deployment
terraform import module.vpc.aws_cloudwatch_log_group.vpc_flow /aws/vpc/insight-edge-nonprod/flow-logs

# Import Secrets Manager secret (after restoring it above)
terraform import module.rds.aws_secretsmanager_secret.db insight-edge/nonprod/db-credentials
```

> If either import returns `Cannot import non-existent remote object`, skip it — Terraform will create it fresh.

### Step 1b — Apply

```powershell
terraform apply
```

### Step 1c — Add ACM Validation CNAMEs to Cloudflare (during apply)

The nonprod cert covers **both** `dev.insight-edgecs.com` and `stage.insight-edgecs.com`.
When you see:
```
module.alb.aws_acm_certificate_validation.main: Still creating... [Xm elapsed]
```

Open a **second terminal** and run:

```powershell
$arns = (aws acm list-certificates --region us-east-1 --query "CertificateSummaryList[*].CertificateArn" --output text) -split '\s+'
foreach ($arn in $arns) {
  aws acm describe-certificate --certificate-arn $arn --region us-east-1 `
    --query "[Certificate.DomainName, Certificate.DomainValidationOptions[*].ResourceRecord]" `
    --output json
}
```

Find the block for `dev.insight-edgecs.com`. It will have **two** validation entries (one for `dev`, one for `stage`). In Cloudflare → `insight-edgecs.com` → DNS → Add **two** records:

| Field | Value |
|-------|-------|
| Type | `CNAME` |
| Name | Everything before `.insight-edgecs.com.` in the `Name` field (e.g. `_abc123.dev`) |
| Target | The `Value` field — remove the trailing dot |
| Proxy status | **DNS only (grey cloud)** |
| TTL | Auto |

Repeat for the `stage` entry (`_abc123.stage`). Terraform detects validation within ~5 minutes and continues automatically.

### Step 1d — Add subdomain CNAMEs after apply completes

Both subdomains point to the **same** ALB. Copy `alb_dns_name` from Terraform output and add two records in Cloudflare:

| Field | dev record | staging record |
|-------|-----------|----------------|
| Type | `CNAME` | `CNAME` |
| Name | `dev` | `stage` |
| Target | `alb_dns_name` output value | same `alb_dns_name` output value |
| Proxy status | **DNS only (grey cloud)** | **DNS only (grey cloud)** |
| TTL | Auto | Auto |

### Step 1e — Verify nonprod

```powershell
nslookup dev.insight-edgecs.com
nslookup stage.insight-edgecs.com
```

Both should return IP addresses. Then open:
- `https://dev.insight-edgecs.com` — expect **"Welcome to Development Environment"** with a padlock
- `https://stage.insight-edgecs.com` — expect **"Welcome to Staging Environment"** with a padlock

---

## Step 2 — Deploy Prod

### Step 2a — Pre-apply imports

```powershell
cd environments/prod
terraform init

# Import CloudWatch log group if it still exists
terraform import module.vpc.aws_cloudwatch_log_group.vpc_flow /aws/vpc/insight-edge-prod/flow-logs

# Import Secrets Manager secret
terraform import module.rds.aws_secretsmanager_secret.db insight-edge/prod/db-credentials
```

> If either import returns `Cannot import non-existent remote object`, skip it.

### Step 2b — Apply

```powershell
terraform apply
```

### Step 2c — Add ACM Validation CNAME to Cloudflare (during apply)

Use the same command from Step 1c. Find the block for `prod.insight-edgecs.com` and add to Cloudflare:

| Field | Value |
|-------|-------|
| Type | `CNAME` |
| Name | Everything before `.insight-edgecs.com.` in the `Name` field (e.g. `_abc123.prod`) |
| Target | The `Value` field — remove the trailing dot |
| Proxy status | **DNS only (grey cloud)** |
| TTL | Auto |

### Step 2d — Add subdomain CNAME after apply completes

| Field | Value |
|-------|-------|
| Type | `CNAME` |
| Name | `prod` |
| Target | `alb_dns_name` output value |
| Proxy status | **DNS only (grey cloud)** |
| TTL | Auto |

### Step 2e — Verify prod

```powershell
nslookup prod.insight-edgecs.com
```

Then open `https://prod.insight-edgecs.com` — expect **"Welcome to Production Environment"** with a padlock.

---

## Step 3 — Cloudflare DNS Summary

By the end you should have **5 CNAME records** in Cloudflare (all grey cloud, DNS only):

| Type | Name | Purpose |
|------|------|---------|
| CNAME | `_<hash>.dev` | ACM cert validation for dev (nonprod cert) |
| CNAME | `_<hash>.stage` | ACM cert validation for staging (nonprod cert) |
| CNAME | `_<hash>.prod` | ACM cert validation for prod |
| CNAME | `dev` | Routes traffic to nonprod ALB |
| CNAME | `stage` | Routes traffic to nonprod ALB (same target as dev) |
| CNAME | `prod` | Routes traffic to prod ALB |

> All records must be grey cloud. Orange cloud breaks ACM certificates and causes SSL errors.
> The `_<hash>` prefix changes on every new deployment — always delete old ACM validation records and add fresh ones.

---

## Step 4 — Confirm SNS Email Subscriptions

After each environment apply, AWS sends a **"Subscription Confirmation"** email to `gabelorm@insight-edgecs.com`. Check inbox and spam — click the confirm link. Without this you receive no alerts.

---

## Step 5 — Final Verification

```powershell
nslookup dev.insight-edgecs.com
nslookup stage.insight-edgecs.com
nslookup prod.insight-edgecs.com
```

All three should return IP addresses. Then verify in browser:

| URL | Expected |
|-----|----------|
| `https://dev.insight-edgecs.com` | Welcome to Development Environment |
| `https://stage.insight-edgecs.com` | Welcome to Staging Environment |
| `https://prod.insight-edgecs.com` | Welcome to Production Environment |

All three should show a padlock (HTTPS working via ACM).

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Apply stuck at ACM validation 30+ min | ACM CNAME not added to Cloudflare — use Step 1c command to get values. Nonprod needs **two** CNAMEs (dev + stage). |
| `ResourceAlreadyExistsException` on log group | Pre-apply import was skipped — run `terraform import module.vpc.aws_cloudwatch_log_group.vpc_flow /aws/vpc/insight-edge-<env>/flow-logs` then `terraform apply` |
| `You can't create this secret because it is scheduled for deletion` | Pre-apply restore was skipped — run `aws secretsmanager restore-secret --secret-id insight-edge/<env>/db-credentials --region us-east-1` then the import command, then `terraform apply` |
| `nslookup` returns no records | Cloudflare CNAME not saved — delete and re-add, click the green checkmark to confirm before leaving the page |
| `nslookup` resolves but browser shows "can't be reached" | Browser cache — try incognito. If it works, go to `chrome://net-internals/#dns` → Clear host cache |
| Site loads but no HTTPS padlock / SSL error | ACM validation CNAME missing or orange cloud is on — check Cloudflare records |
| 502 Bad Gateway | EC2 instances not yet healthy — wait 5–10 minutes, check EC2 → Target Groups |
| Prod terraform destroy — ALB deletion protection | Run: `aws elbv2 modify-load-balancer-attributes --load-balancer-arn <arn> --attributes Key=deletion_protection.enabled,Value=false --region us-east-1` |
| Prod terraform destroy — RDS not in available state | Check: `aws rds describe-db-instances --db-instance-identifier insight-edge-prod-primary --query "DBInstances[0].DBInstanceStatus" --region us-east-1 --output text` — wait for `available` then re-run destroy |
