# Architecture Changes: Old Design → New Terraform Implementation

This document records every component that exists in the new Terraform infrastructure
but was absent or different in the original architecture diagram (`architecture_work.jpeg`).
It also lists corrections that must be applied to `AWS_Infra_GRA.drawio`.

---

## 1. WHAT CHANGED: Side-by-Side Comparison

| Component | Old Design | New Terraform Work | Status in draw.io |
|---|---|---|---|
| Admin Access | OpenVPN Instance in Management box | AWS SSM Session Manager (no VPN, no ports open) | Partially fixed — text updated but icon still uses VPN shape |
| Application Servers | Single EC2 Application Server | Auto Scaling Group (ASG) with min/desired/max per env | ❌ NOT added |
| Private subnet egress | No NAT gateway shown | NAT Gateway per AZ (1 in dev/staging, 2 in prod for HA) | ❌ NOT added |
| TLS/HTTPS | ALB shown, certs implied | ACM Certificate explicitly provisioned and DNS-validated | ❌ NOT added |
| Monitoring | Not shown | CloudWatch (11 alarms: CPU, memory, disk, latency, DB lag, errors) | ❌ NOT added |
| Alerting | Not shown | SNS Topic → email subscriptions (CloudWatch alarm actions) | ❌ NOT added |
| Audit Logging | Not shown | CloudTrail (multi-region, log file validation, S3 + CloudWatch Logs) | ❌ NOT added |
| Threat Detection | Not shown | AWS GuardDuty (S3 data events, EBS malware scan, runtime monitoring) | ❌ NOT added |
| Database Credentials | Not shown | AWS Secrets Manager (auto-generated 20-char password, never in code) | ❌ NOT added |
| Network Traffic Logs | Not shown | VPC Flow Logs (logged to CloudWatch Logs) | ❌ NOT added |
| Cost Control | Not shown | AWS Budgets (alerts at 80% and 100% of monthly limit) | ❌ NOT added |
| AZ2 Public Subnet | Not shown (only AZ1 had public subnet) | Public subnet in both AZ1 and AZ2 (ALB is multi-AZ) | ❌ NOT added |
| S3 Buckets | One bucket shown: "Terraform state & backups" | Two buckets: (1) State bucket (bootstrap), (2) App data + ALB logs (per env) | ❌ Label not updated |
| Environment names | Dev / Demo / Prod | Dev / Stage / Prod | ❌ "Demo" still in CIDR blocks and Resource Tags |
| VPN DNS footnote | insight-edge-demo.com domain | insight-edgecs.com domain (updated) — but VPN is fully removed | ❌ VPN DNS footnote still present, must be removed |
| ALB DNS footnote | insight-edge-demo.com | dev/stage/prod.insight-edgecs.com | ✅ Already updated |

---

## 2. NEW COMPONENTS TO ADD TO DRAW.IO

### 2.1 NAT Gateway
**Where:** Inside the public subnet of each AZ (AZ1 and AZ2).
**Appearance:** Place it beside or below the ALB in the public subnet box.
**Connections:** Draw an arrow from the private subnet App Servers → NAT Gateway (for outbound internet traffic).
**Note for prod:** Show 2 NAT Gateways (one per AZ) to represent high availability. Dev and staging use only 1 (in AZ1).
**AWS draw.io shape:** `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.nat_gateway`
**Why added:** Private subnet servers have no direct internet access. NAT gateways provide outbound-only internet connectivity (e.g., to download packages, reach AWS APIs). Without them, EC2 instances in private subnets cannot reach the internet at all. Prod uses 2 for fault tolerance — if AZ1 fails, AZ2 instances can still reach the internet.

---

### 2.2 Auto Scaling Group (ASG)
**Where:** Wrap the existing "Application Server" EC2 icon in an ASG boundary box inside the private subnet.
**Label:** Show "Auto Scaling Group" as the container, with EC2 instances inside.
**Per-environment sizes to note (can be in footnotes):**
- Dev: min=1 / desired=1 / max=2
- Stage: min=2 / desired=2 / max=4
- Prod: min=2 / desired=2 / max=6
**AWS draw.io shape:** `shape=mxgraph.aws4.group;grIcon=mxgraph.aws4.group_auto_scaling_group`
**Why added:** The new infrastructure does not run a fixed EC2 instance. It uses an ASG with a Launch Template that auto-replaces failed instances, scales up under load, and performs rolling updates. This is a fundamental architectural change from the original single-server design.

---

### 2.3 ACM Certificate (AWS Certificate Manager)
**Where:** Show as a small box attached to or near the ALB, or in a separate "Security" lane outside the VPC.
**Label:** "ACM Certificate (TLS)"
**Connection:** Arrow from ACM → ALB (ALB uses the cert for HTTPS).
**AWS draw.io shape:** `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.certificate_manager`
**Why added:** The ALB serves HTTPS on port 443. The TLS certificate is provisioned via ACM with DNS validation through Route 53. This is a separate AWS service that must be explicitly shown — it is not "built into" the ALB.

---

### 2.4 CloudWatch (Monitoring)
**Where:** Outside the VPC box, in a new "Monitoring & Observability" section (can be placed below or to the right of the main VPC block).
**Label:** "CloudWatch (Monitoring & Alarms)"
**Sub-components to note:** 11 alarms covering:
- EC2: CPU > 80%, Memory > 85%, Disk > 85%
- ALB: Latency > 1s, 5xx errors > 10/min, Unhealthy host count > 0
- RDS: CPU > 80%, free storage < 2 GB, connections > 80, replica lag > 30s
- ASG: CPU sustained > 75% (scale-out trigger)
**Connections:** Arrows from EC2 ASG, ALB, RDS → CloudWatch; CloudWatch → SNS (for alarm notifications).
**AWS draw.io shape:** `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.cloudwatch`
**Why added:** Production-grade infrastructure requires active monitoring. CloudWatch is the central monitoring service receiving metrics from EC2 (via the CloudWatch agent installed by user_data.sh), ALB, and RDS, and triggering alarms when thresholds are breached.

---

### 2.5 SNS (Simple Notification Service)
**Where:** Next to or below CloudWatch in the monitoring section.
**Label:** "SNS Topic (Email Alerts)"
**Connection:** Arrow from CloudWatch alarms → SNS; SNS → Email (external symbol).
**AWS draw.io shape:** `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.sns`
**Why added:** CloudWatch alarms do not send emails directly — they publish to an SNS topic. Engineers subscribe their email addresses to the SNS topic and receive notifications when any alarm fires (e.g., DB CPU high, ALB returning 5xx errors). GuardDuty findings also publish to SNS.

---

### 2.6 CloudTrail (Audit Logging)
**Where:** Outside the VPC, in an "Account-Level Services" section (alongside GuardDuty and Budgets). This is a bootstrap-level service — it applies to the entire AWS account, not per-environment.
**Label:** "CloudTrail (Audit Log)"
**Connection:** Arrow from CloudTrail → S3 State Bucket (logs stored there) and optionally → CloudWatch Logs.
**AWS draw.io shape:** `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.cloudtrail`
**Why added:** CloudTrail records every API call made in the AWS account (who did what, when, from where). It is a security and compliance requirement. Multi-region coverage and log file validation are enabled. Without CloudTrail, there is no audit trail if credentials are compromised or unauthorized changes are made.

---

### 2.7 GuardDuty (Threat Detection)
**Where:** In the same "Account-Level Services" section as CloudTrail and Budgets.
**Label:** "GuardDuty (Threat Detection)"
**Connection:** Arrow from GuardDuty → SNS (findings trigger email alerts).
**AWS draw.io shape:** `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.guardduty`
**Why added:** GuardDuty is an intelligent threat detection service that monitors network traffic, CloudTrail events, DNS logs, and S3 data events for malicious activity. It detects things like cryptocurrency mining, credential exfiltration, unusual API calls, and port scanning. Enabled features: S3 data event analysis, EBS malware scanning, runtime monitoring for EC2.

---

### 2.8 Secrets Manager
**Where:** Outside the VPC box but connected to both the RDS instance and the EC2 ASG instances.
**Label:** "Secrets Manager (DB Credentials)"
**Connection:** Arrows from EC2 ASG → Secrets Manager (app fetches credentials at runtime), and Secrets Manager → RDS (password stored here was used to create the DB).
**AWS draw.io shape:** `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.secrets_manager`
**Why added:** The RDS database password is never stored in Terraform state, environment variables, or configuration files. It is auto-generated as a 20-character random string and stored exclusively in Secrets Manager. Application code retrieves it at runtime via the AWS SDK. This prevents credential leakage in git history, logs, or config files.

---

### 2.9 VPC Flow Logs
**Where:** A small annotation on the VPC box itself, or a separate symbol in the monitoring section with an arrow from VPC → CloudWatch Logs.
**Label:** "VPC Flow Logs → CloudWatch Logs"
**AWS draw.io shape:** Can use a note/annotation shape or `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.vpc_flow_logs`
**Why added:** VPC Flow Logs capture metadata about all network traffic in and out of the VPC (source IP, destination IP, ports, accepted/rejected). This is critical for security forensics, network troubleshooting, and detecting unusual traffic patterns. Logs are shipped to CloudWatch Logs for querying.

---

### 2.10 AWS Budgets
**Where:** In the "Account-Level Services" section alongside CloudTrail and GuardDuty.
**Label:** "AWS Budgets (Cost Alerts)"
**Connection:** Arrow from Budgets → SNS (email alerts at 80% and 100% of monthly limit).
**AWS draw.io shape:** `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.budgets` or use the Cost Management icon.
**Why added:** Cloud costs can spike unexpectedly (runaway auto-scaling, forgotten resources, unexpected data transfer). Budget alerts at 80% and 100% of the monthly limit provide early warning before bills exceed expectations. This is a bootstrap-level service (set up once for the account).

---

### 2.11 AZ2 Public Subnet
**Where:** Add a "Public subnet" box inside the AZ2 block (currently AZ2 only shows a Private subnet).
**Contents:** NAT Gateway (for prod HA) and the ALB cross-zone endpoint symbol.
**Why added:** The Application Load Balancer is multi-AZ by design. It has nodes in both AZ1 and AZ2 public subnets. The old diagram only showed a public subnet in AZ1, which implies the ALB is single-AZ — that is incorrect. In prod, the second NAT gateway also lives in AZ2's public subnet.

---

### 2.12 Two Separate S3 Buckets
**Current label:** "S3 Bucket (Terraform state & backups)"
**Correct representation:** Two distinct S3 buckets:
1. **State Bucket** (bootstrap): `insight-edge-terraform-state-310688446551` — holds Terraform state files for all environments. Versioned, encrypted, public access blocked. (Account-level)
2. **App Data Bucket** (per environment): Holds application uploads and ALB access logs. Versioned, encrypted, public access blocked. (Per-environment)
**Why separated:** The original diagram conflated these two into one. They are created by different Terraform stacks (bootstrap vs. per-environment), have different purposes, different IAM access policies, and different lifecycles.

---

## 3. FIXES TO APPLY (Errors in Current draw.io)

### Fix 1: "Demo" → "Stage" in VPC CIDR Blocks footnote
**Current text:** `Demo: 10.0.4.0/22`
**Correct text:** `Stage: 10.0.4.0/22`
**Why:** The staging environment is called "stage" throughout the entire Terraform codebase. The old project called it "Demo" — that naming was abandoned when the domain was changed and the code was refactored.

### Fix 2: "Demo" → "Stage" in Resource Tags footnote
**Current text:** `Demo: Environment: Demo`
**Correct text:** `Stage: Environment: Staging`
**Why:** Same reason as above. All Terraform resources in the staging environment are tagged `Environment = "staging"`.

### Fix 3: Remove VPN Server DNS from footnotes
**Current text:** VPN Server DNS section with vpn-dev.insight-edgecs.com, vpn-stage.insight-edgecs.com, vpn.insight-edgecs.com
**Action:** Delete this entire footnote section.
**Why:** The VPN module exists in the code but is completely unused. Admin access is exclusively via AWS SSM Session Manager. There is no VPN server running. Showing VPN DNS entries is misleading — no VPN records are created in Route 53.

### Fix 4: Fix SSM Session Manager icon in Management box
**Current state:** The SSM Session Manager label uses the `mxgraph.veeam2.open_vpn` shape (VPN icon in orange). The text was updated but the icon was not.
**Action:** Change the shape style to use the AWS Systems Manager icon: `shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.systems_manager`
**Why:** Showing a VPN icon next to "SSM Session Manager" is visually misleading and technically incorrect.

### Fix 5: Orphaned VPN icon in Legend (line 257)
**Current state:** An `open_vpn` shaped icon with `value=""` exists in the legend — it is the leftover OpenVPN legend entry with its label cleared but the icon shape not removed.
**Action:** Either remove this shape entirely, or replace it with the SSM Session Manager icon properly.
**Why:** An unlabeled icon in the legend makes the diagram confusing.

---

## 4. ACCOUNT-LEVEL SERVICES SECTION (NEW SECTION TO ADD)

The original diagram has no representation of account-wide services. These should be shown in a clearly-labelled outer box titled **"AWS Account-Level Services (Bootstrap)"** placed outside and above the VPC:

| Service | Purpose |
|---|---|
| CloudTrail | API audit logging |
| GuardDuty | Threat detection |
| AWS Budgets | Cost alerts |
| S3 State Bucket | Terraform remote state |
| DynamoDB Lock Table | Terraform state locking |
| Route 53 Hosted Zone | DNS for insight-edgecs.com |
| IAM Password Policy | Account security policy |

---

## 5. UPDATED LEGEND ENTRIES NEEDED

The Legend box needs these new entries added:

| Icon | Label |
|---|---|
| NAT Gateway icon | NAT Gateway |
| Auto Scaling Group icon | Auto Scaling Group (ASG) |
| CloudWatch icon | CloudWatch (Monitoring) |
| SNS icon | SNS (Notifications) |
| Secrets Manager icon | Secrets Manager |
| GuardDuty icon | GuardDuty |
| CloudTrail icon | CloudTrail |
| ACM icon | ACM Certificate |

---

## 6. UPDATED FOOTNOTES

### VPC CIDR Blocks (corrected):
- Dev: 10.0.0.0/22
- Stage: 10.0.4.0/22  ← was "Demo"
- Prod: 10.0.8.0/22

### Resource Tags (corrected):
- Dev: Environment: Development
- Stage: Environment: Staging  ← was "Demo: Environment: Demo"
- Prod: Environment: Production

### ALB DNS (already correct):
- Dev: dev.insight-edgecs.com
- Stage: stage.insight-edgecs.com
- Prod: prod.insight-edgecs.com

### Admin Access (replace VPN Server DNS section):
- All environments: AWS SSM Session Manager (no open ports, no VPN, no key pairs required)
- DB access: SSM port forwarding to RDS private IP:5432

### NAT Gateway (new footnote):
- Dev: 1 NAT Gateway (AZ1 only, cost-optimized)
- Stage: 1 NAT Gateway (AZ1 only, cost-optimized)
- Prod: 2 NAT Gateways (one per AZ, high availability)

### ASG Configuration (new footnote):
- Dev: min=1 / desired=1 / max=2
- Stage: min=2 / desired=2 / max=4
- Prod: min=2 / desired=2 / max=6

---

## 7. SUMMARY: WHAT'S NEW vs OLD

### Components REMOVED from old design:
- OpenVPN Instance (replaced by SSM Session Manager)

### Components ADDED in new design (not in old diagram):
1. NAT Gateway (per AZ in each environment)
2. Auto Scaling Group wrapping EC2 instances
3. ACM Certificate (TLS for ALB)
4. CloudWatch (monitoring + 11 alarms)
5. SNS (email alert notifications)
6. CloudTrail (account-wide audit log)
7. GuardDuty (account-wide threat detection)
8. Secrets Manager (database credential storage)
9. VPC Flow Logs (network traffic metadata)
10. AWS Budgets (cost alerts at 80%/100%)
11. AZ2 Public Subnet (ALB multi-AZ node)
12. DynamoDB Lock Table (Terraform state locking)
13. Second S3 bucket (per-env app data + ALB logs)

### Text/Label Fixes needed in draw.io:
- "Demo" → "Stage" in CIDR blocks and Resource Tags
- Remove VPN Server DNS footnote section
- Fix SSM icon shape (currently using VPN icon shape)
- Remove orphaned VPN icon from legend
