# Gabriel_Infra — Deployment Report

**Project:** Gabriel_Infra  
**Domain:** insight-edgecs.com (Namecheap)  
**Cloud:** AWS — us-east-1  
**AWS Account ID:** 310688446551  

---

## What Was Built

A complete AWS infrastructure-as-code project using Terraform. It provisions three isolated environments — **dev, staging, prod** — each containing a full application stack. A one-time **bootstrap** layer handles account-wide setup.

---

## Infrastructure Components & Why Each One Exists

| Component | Why |
|---|---|
| **VPC** | Isolates each environment in its own private network. Dev/Staging/Prod cannot talk to each other. |
| **Public Subnets (AZ1 + AZ2)** | Host the ALB and NAT Gateways. Must be public to receive internet traffic. |
| **Private Subnets (AZ1 + AZ2)** | Host app servers and the database. Never directly reachable from the internet. |
| **Internet Gateway** | Entry point for all inbound traffic from the internet into the VPC. |
| **NAT Gateway** | Lets private-subnet EC2 instances make outbound calls (package downloads, AWS API calls) without being publicly reachable. Dev/Stage use 1; Prod uses 2 (one per AZ) for HA. |
| **Application Load Balancer (ALB)** | Distributes HTTPS traffic across EC2 instances in both AZs. Handles HTTP→HTTPS redirect. |
| **WAFv2** | Sits in front of the ALB. Blocks OWASP top 10 attacks, SQL injection, bad IPs, and rate-limits requests (2000/5min dev/stage, 1000/5min prod). |
| **ACM Certificate** | Provides the TLS cert for HTTPS on the ALB. Validated automatically via Route 53 DNS. |
| **Auto Scaling Group (ASG)** | Manages EC2 instances. Auto-replaces failed instances, scales up under load, and enables zero-downtime rolling deploys. |
| **EC2 (Ubuntu 22.04)** | The application servers. Run nginx on port 8080 with a `/health` endpoint. CloudWatch agent is installed at launch via `user_data.sh`. |
| **RDS PostgreSQL 16.3** | Primary database in AZ1 + read replica in AZ2. Password is auto-generated and stored in Secrets Manager — never in code. |
| **Secrets Manager** | Stores the RDS password. EC2 instances fetch credentials at runtime via the AWS SDK. Nothing sensitive is in Terraform state or environment variables. |
| **S3 Bucket (per env)** | Stores application file uploads and ALB access logs. Versioned, encrypted, public access blocked. |
| **Cognito** | User authentication. Email sign-in, OAuth2/PKCE client, configurable callback URLs per environment. |
| **CloudWatch** | Monitors the stack with 11 alarms across EC2 (CPU/memory/disk), ALB (latency/5xx/unhealthy hosts), and RDS (CPU/storage/connections/replica lag). |
| **SNS** | CloudWatch alarms and GuardDuty findings publish here. Engineers subscribe their email to receive alerts. |
| **Route 53** | DNS management for insight-edgecs.com. Bootstrap creates the hosted zone. Per-env ALB records are created automatically by Terraform. |
| **CloudTrail** | Account-wide audit log. Records every AWS API call — who, what, when, from where. Bootstrap-level. |
| **GuardDuty** | Threat detection. Monitors network traffic, S3 data events, EBS volumes, and EC2 runtime for malicious activity. Bootstrap-level. |
| **AWS Budgets** | Sends email alerts at 80% and 100% of a monthly cost ceiling. Bootstrap-level. |
| **DynamoDB (state lock)** | Prevents two people from running `terraform apply` at the same time. Bootstrap-level. |
| **SSM Session Manager** | How you get a shell into EC2 instances and tunnel to RDS. No SSH ports are open. No key pairs are needed for day-to-day access. |

---

## Where to Make Changes Before Deploying

### Step 1 — Bootstrap (`bootstrap/`)

Run this once. It creates the S3 state bucket, Route 53 hosted zone, CloudTrail, GuardDuty, and Budgets.

```bash
cd bootstrap
terraform init
terraform apply \
  -var='budget_alert_emails=["your@email.com"]' \
  -var='monthly_budget_usd=600'
```

After apply, note the output values:
- `route53_zone_id` — you will paste this into every environment's `terraform.tfvars`
- `name_servers` — you will paste these four values into Namecheap

**Nothing in `bootstrap/` needs editing** unless you want to change the region or project name.

---

### Step 2 — Namecheap DNS

1. Log in to Namecheap → Domain List → insight-edgecs.com → Manage
2. Under **Nameservers**, select **Custom DNS**
3. Paste the 4 nameservers from the Bootstrap `name_servers` output
4. Wait 15–60 minutes for propagation

**This must be done before deploying any environment.** ACM certificate validation will hang if Route 53 is not the authoritative nameserver.

---

### Step 3 — Environment tfvars

Each environment has one file to edit before deploying:

| Environment | File |
|---|---|
| Dev | `environments/dev/terraform.tfvars` |
| Staging | `environments/staging/terraform.tfvars` |
| Prod | `environments/prod/terraform.tfvars` |

**Fields to fill in / verify for every environment:**

```hcl
# Already set — verify these match your account
aws_region      = "us-east-1"
project_name    = "insight-edge"
domain_name     = "insight-edgecs.com"

# Paste from Bootstrap output
route53_zone_id = "Z03874001XT5UX4ZUS33K"   # ← already filled

# Your EC2 key pair name (create one in AWS Console → EC2 → Key Pairs)
key_pair_name   = "infratest"                 # ← change to your key pair name

# Add at least one email to receive CloudWatch and GuardDuty alerts
alert_emails    = ["your@email.com"]          # ← currently empty, fill this in
```

Everything else (CIDRs, instance types, ASG sizes, WAF rate limits) is pre-configured per environment and does not need to change unless you want to resize.

---

### Step 4 — Deploy Environments

Deploy in order: dev → staging → prod. Each takes 15–25 minutes (RDS initialization).

```bash
cd environments/dev
terraform init
terraform plan
terraform apply

cd ../staging
terraform init && terraform plan && terraform apply

cd ../prod
terraform init && terraform plan && terraform apply
```

---

### Step 5 — Confirm SNS Email Subscriptions

After each `apply`, AWS sends a confirmation email to every address in `alert_emails`. **You must click the confirmation link** or you will not receive any alerts.

---

## Key Configuration Values (Pre-filled)

| Value | Where it comes from | Current value |
|---|---|---|
| AWS Account ID | Your AWS account | `310688446551` |
| Route 53 Zone ID | Bootstrap output | `Z03874001XT5UX4ZUS33K` |
| State bucket | Bootstrap creates it | `insight-edge-terraform-state-310688446551` |
| Dev URL | Auto-created by ALB module | `https://dev.insight-edgecs.com` |
| Staging URL | Auto-created by ALB module | `https://stage.insight-edgecs.com` |
| Prod URL | Auto-created by ALB module | `https://prod.insight-edgecs.com` |
| DB credentials | Auto-generated, stored in Secrets Manager | Retrieved at runtime — never hardcoded |

---

## Application Deployment (Post-Infrastructure)

Once the infrastructure is up, deploy your app to the EC2 instances:

```bash
# 1. Get an instance ID from the ASG
INSTANCE=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $(terraform -chdir=environments/dev output -raw asg_name) \
  --query 'AutoScalingGroups[0].Instances[0].InstanceId' --output text)

# 2. Shell in via SSM (no SSH, no key pair needed)
aws ssm start-session --target $INSTANCE

# 3. On the instance — deploy your app
cd /opt/app
# pull your code, install dependencies, start your process on port 8080
```

Your app must:
- Listen on port **8080**
- Respond to `GET /health` with HTTP 200

The ALB will not route traffic to any instance that fails the health check.

---

## Monthly Cost Estimate

| Environment | Est. cost/month |
|---|---|
| Dev | ~$95 |
| Staging | ~$166 |
| Prod | ~$331 |
| Account-level (bootstrap) | ~$7 |
| **All three running** | **~$599** |

NAT Gateways are the biggest idle cost (~$33/month each). Tear down dev and staging when not in use to save ~$250/month.

```bash
# Tear down dev (reverse order matters — prod last)
cd environments/dev && terraform destroy
```

---

## Architecture Changes Applied to Draw.io

The file `AWS_Infra_GRA.drawio` has been updated. Changes made:

**Fixes:**
- SSM icon corrected (was using VPN icon shape)
- "Demo" renamed to "Stage" in CIDR blocks and Resource Tags footnote
- VPN Server DNS footnote removed and replaced with Admin Access (SSM) section

**New components added to diagram:**
- NAT Gateway (AZ1 public subnet)
- AZ2 Public Subnet + NAT Gateway (prod HA)
- ACM Certificate
- Auto Scaling Group wrapper around App Server
- CloudWatch (Monitoring & Observability section)
- SNS (Email Alerts)
- Secrets Manager
- VPC Flow Logs
- CloudTrail (Account-Level Services section)
- GuardDuty
- AWS Budgets
- DynamoDB State Lock
- Second S3 bucket (app data + ALB logs)

To see the updated diagram: open `AWS_Infra_GRA.drawio` in draw.io → **File → Revert** (or close and reopen).

Full change details are in `ARCHITECTURE_CHANGES.md`.
