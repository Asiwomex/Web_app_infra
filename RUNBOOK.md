# Deployment Runbook — Full Redeploy from Scratch

Use this after a `terraform destroy` to bring all three environments back up.
Domain: `insight-edgecs.com` | AWS Account: `310688446551` | Region: `us-east-1`

---

## Prerequisites

- AWS CLI configured (`aws sts get-caller-identity` returns your account ID)
- Terraform installed (`terraform version` returns 1.9.0+)
- Bootstrap already applied — S3 state bucket exists (do NOT re-run bootstrap)
- `insight-edgecs.com` DNS managed in Cloudflare

---

## Step 1 — Deploy Dev

```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

### Step 1a — Add ACM Validation CNAME to Cloudflare (during apply)

When you see:
```
module.alb.aws_acm_certificate_validation.main: Still creating... [Xm elapsed]
```

Open a **second terminal** and run:

```powershell
$arns = (aws acm list-certificates --region us-east-1 --query "CertificateSummaryList[*].CertificateArn" --output text) -split '\s+'
foreach ($arn in $arns) {
  aws acm describe-certificate --certificate-arn $arn --region us-east-1 `
    --query "[Certificate.DomainName, Certificate.DomainValidationOptions[0].ResourceRecord]" `
    --output json
}
```

In Cloudflare → `insight-edgecs.com` → DNS → Records → Add record:

| Field | Value |
|-------|-------|
| Type | `CNAME` |
| Name | Everything before `.insight-edgecs.com.` in the `Name` field (e.g. `_abc123.dev`) |
| Target | The `Value` field — remove the trailing dot |
| Proxy status | **DNS only (grey cloud)** |
| TTL | Auto |

Save. Terraform detects validation within ~5 minutes and continues automatically.

### Step 1b — Fix known errors if they appear

**CloudWatch log group already exists:**
```powershell
cd environments/dev
terraform import module.vpc.aws_cloudwatch_log_group.vpc_flow /aws/vpc/insight-edge-dev/flow-logs
terraform apply
```

**Secrets Manager secret scheduled for deletion:**
```powershell
aws secretsmanager restore-secret --secret-id insight-edge/dev/db-credentials --region us-east-1
terraform import module.rds.aws_secretsmanager_secret.db insight-edge/dev/db-credentials
terraform apply
```

### Step 1c — Add subdomain CNAME after apply completes

When apply finishes, copy the `alb_dns_name` from the output. In Cloudflare add:

| Field | Value |
|-------|-------|
| Type | `CNAME` |
| Name | `dev` |
| Target | `alb_dns_name` output value |
| Proxy status | **DNS only (grey cloud)** |
| TTL | Auto |

### Step 1d — Verify dev

```powershell
nslookup dev.insight-edgecs.com
```

Should return IP addresses. Then open `https://dev.insight-edgecs.com` — expect **"Welcome to Development Environment"** with a padlock.

---

## Step 2 — Deploy Staging

```bash
cd environments/staging
terraform init
terraform plan
terraform apply
```

Follow the same sub-steps as dev:
- **Step 2a** — Add ACM validation CNAME to Cloudflare (same command, look for `stage.insight-edgecs.com` in output)
- **Step 2b** — Fix known errors if they appear (replace `dev` with `staging` in the import commands)
- **Step 2c** — Add `stage` subdomain CNAME in Cloudflare pointing to `alb_dns_name` output
- **Step 2d** — Verify: `nslookup stage.insight-edgecs.com` then `https://stage.insight-edgecs.com`

**Known error fix for staging:**
```powershell
# CloudWatch log group
terraform import module.vpc.aws_cloudwatch_log_group.vpc_flow /aws/vpc/insight-edge-staging/flow-logs

# Secrets Manager
aws secretsmanager restore-secret --secret-id insight-edge/staging/db-credentials --region us-east-1
terraform import module.rds.aws_secretsmanager_secret.db insight-edge/staging/db-credentials
```

---

## Step 3 — Deploy Prod

```bash
cd environments/prod
terraform init
terraform plan
terraform apply
```

Follow the same sub-steps:
- **Step 3a** — Add ACM validation CNAME to Cloudflare (look for `prod.insight-edgecs.com`)
- **Step 3b** — Fix known errors if they appear
- **Step 3c** — Add `prod` subdomain CNAME in Cloudflare pointing to `alb_dns_name` output
- **Step 3d** — Verify: `nslookup prod.insight-edgecs.com` then `https://prod.insight-edgecs.com`

**Known error fix for prod:**
```powershell
# CloudWatch log group
terraform import module.vpc.aws_cloudwatch_log_group.vpc_flow /aws/vpc/insight-edge-prod/flow-logs

# Secrets Manager
aws secretsmanager restore-secret --secret-id insight-edge/prod/db-credentials --region us-east-1
terraform import module.rds.aws_secretsmanager_secret.db insight-edge/prod/db-credentials
```

---

## Step 4 — Cloudflare DNS Summary

By the end you should have **6 CNAME records** in Cloudflare (all grey cloud, DNS only):

| Type | Name | Purpose |
|------|------|---------|
| CNAME | `_<hash>.dev` | ACM cert validation for dev |
| CNAME | `_<hash>.stage` | ACM cert validation for staging |
| CNAME | `_<hash>.prod` | ACM cert validation for prod |
| CNAME | `dev` | Routes traffic to dev ALB |
| CNAME | `stage` | Routes traffic to staging ALB |
| CNAME | `prod` | Routes traffic to prod ALB |

> All 6 records must be grey cloud. Orange cloud breaks ACM certificates and causes SSL errors.

---

## Step 5 — Confirm SNS Email Subscriptions

After each environment apply, AWS sends a **"Subscription Confirmation"** email to `gabelorm@insight-edgecs.com`. Check inbox and spam — click the confirm link. Without this you receive no alerts.

---

## Step 6 — Final Verification

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
| Apply stuck at ACM validation 30+ min | ACM CNAME not added to Cloudflare — use Step 1a command to get values |
| `nslookup` returns no records | Cloudflare CNAME not saved — delete and re-add, click the green checkmark to confirm before leaving the page |
| `nslookup` resolves but browser shows "can't be reached" | Browser cache — try incognito window. If it works, go to `chrome://net-internals/#dns` → Clear host cache |
| Site loads but no HTTPS padlock / SSL error | ACM validation CNAME missing or orange cloud is on — check Cloudflare records |
| 502 Bad Gateway | EC2 instances not yet healthy — wait 5–10 minutes, check EC2 → Target Groups |
| `ResourceAlreadyExistsException` on log group | Run the CloudWatch import command in Step 1b/2b/3b |
| `You can't create this secret because it is scheduled for deletion` | Run the Secrets Manager restore + import commands in Step 1b/2b/3b |
