# Pre-Flight Checklist — Read This Before Running Any Terraform Command

This document walks you through every tool you need to install, every account you need to set up, and every decision you need to make **before** you run `terraform apply` for the first time. Follow every section in order.

---

## Glossary — What These Words Mean

If you are new to cloud infrastructure, these terms appear constantly. Bookmark this section.

| Term | Plain-English meaning |
|------|----------------------|
| **AWS** | Amazon Web Services — the cloud platform that hosts everything this project creates (servers, databases, networking, etc.) |
| **Terraform** | A command-line tool that reads `.tf` files and creates/manages cloud resources automatically. Think of it as a recipe book that builds your infrastructure. |
| **IAM** | Identity and Access Management — AWS's system for controlling who (users, applications) can do what |
| **VPC** | Virtual Private Cloud — your own private network inside AWS, isolated from everyone else |
| **EC2** | Elastic Compute Cloud — virtual servers ("instances") that run your applications |
| **RDS** | Relational Database Service — managed PostgreSQL/MySQL/etc. databases |
| **ALB** | Application Load Balancer — sits in front of your servers and distributes incoming web traffic |
| **WAF** | Web Application Firewall — filters malicious web requests before they reach your servers |
| **S3** | Simple Storage Service — cloud file storage (like Google Drive, but for servers) |
| **Route 53** | AWS's DNS service — translates domain names (e.g. `app.example.com`) to server IP addresses |
| **Cognito** | AWS's user authentication service — handles sign-up, sign-in, and tokens |
| **GuardDuty** | AWS's threat-detection service — monitors your account for suspicious activity |
| **CloudTrail** | Audit log of every API call made in your AWS account |
| **SNS** | Simple Notification Service — sends emails/SMS/alerts when alarms fire |
| **EIP** | Elastic IP — a fixed, public IP address you can attach to a server |
| **NAT Gateway** | Lets servers in private subnets reach the internet without being publicly accessible themselves |
| **ASG** | Auto Scaling Group — automatically adds or removes servers based on load |
| **Hosted Zone** | A container in Route 53 that holds all the DNS records for one domain |
| **Terraform State** | A file (stored in S3) that Terraform uses to remember what resources it already created |
| **Backend** | Where Terraform stores its state file — in this project, an S3 bucket |

---

## Section 1 — Create an AWS Account

If you already have an AWS account you own and can administer, skip to Section 2.

1. Go to [https://aws.amazon.com](https://aws.amazon.com) and click **Create an AWS Account**.
2. Enter your email address and choose an account name (e.g. "MyProject").
3. You will need a **credit card** — AWS bills you for what you use. Section 13 explains expected costs (~$100–$315/month per environment).
4. Complete phone verification.
5. Choose the **Basic support plan** (free) on the last step.
6. Sign in to the [AWS Management Console](https://console.aws.amazon.com).

> **Important:** You are now signed in as the **root user**. Never use the root user for day-to-day work. Section 2 creates a safer admin user.

---

## Section 2 — Create an IAM Admin User (Do Not Use Root)

The root account has unlimited power with no audit trail. Create a dedicated admin IAM user instead.

1. In the AWS Console search bar, type **IAM** and click the service.
2. In the left menu, click **Users** → **Create user**.
3. Enter a username (e.g. `terraform-admin`).
4. Check **Provide user access to the AWS Management Console** → choose **I want to create an IAM user** → set a password.
5. On the next screen, choose **Attach policies directly** → search for and select **AdministratorAccess**.
6. Click through to **Create user**.
7. **Download the CSV** on the confirmation screen — it contains this user's login URL, username, and password. Store it safely.

Now sign out of the root account and sign back in using the new IAM user URL from the CSV.

### Create Access Keys (for the CLI)

Terraform uses the AWS CLI to authenticate, which needs access keys — not your console password.

1. Still in IAM, click your new user → **Security credentials** tab.
2. Scroll to **Access keys** → **Create access key**.
3. Choose **Command Line Interface (CLI)** → check the acknowledgement → **Next** → **Create access key**.
4. **Download the CSV** or copy both values immediately:
   - **Access key ID** (starts with `AKIA…`)
   - **Secret access key** (long random string — you can never view it again)

---

## Section 2B — Install the AWS CLI

The AWS CLI is a terminal program that lets Terraform authenticate with your AWS account.

### Windows

1. Download the installer: [https://awscli.amazonaws.com/AWSCLIV2.msi](https://awscli.amazonaws.com/AWSCLIV2.msi)
2. Run the installer (accept all defaults).
3. Open a **new** Command Prompt or PowerShell window and verify:
   ```
   aws --version
   ```
   Expected output: `aws-cli/2.x.x Python/3.x.x Windows/…`

### macOS

```bash
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
aws --version
```

### Linux (Ubuntu/Debian)

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

### Configure the CLI with your credentials

Run this command and enter the values from Section 2 when prompted:

```bash
aws configure
```

```
AWS Access Key ID [None]: AKIA...          ← paste your access key ID
AWS Secret Access Key [None]: ...          ← paste your secret access key
Default region name [None]: us-east-1     ← type this exactly
Default output format [None]: json        ← type this exactly
```

**Verify it works:**

```bash
aws sts get-caller-identity
```

Expected output (values will differ):

```json
{
    "UserId": "AIDA...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/terraform-admin"
}
```

Write down the 12-digit `Account` number — you will need it in Section 9.

> If you see `Unable to locate credentials`, the configure step did not save correctly. Run `aws configure` again.

---

## Section 3 — Install Terraform

Terraform is the tool that reads the `.tf` files in this repository and creates your AWS resources.

### Windows

1. Go to [https://developer.hashicorp.com/terraform/downloads](https://developer.hashicorp.com/terraform/downloads)
2. Download the **Windows AMD64** zip file.
3. Extract the zip — you get a single file called `terraform.exe`.
4. Move `terraform.exe` to a folder like `C:\terraform\`.
5. Add it to your PATH:
   - Search Windows for "Environment Variables" → click "Edit the system environment variables".
   - Click **Environment Variables** → under "System variables" find `Path` → click **Edit**.
   - Click **New** → type `C:\terraform` → click OK on all dialogs.
6. Open a **new** PowerShell window and verify:
   ```
   terraform version
   ```
   Expected: `Terraform v1.x.x`

### macOS (with Homebrew)

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
terraform version
```

### Linux (Ubuntu/Debian)

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
terraform version
```

---

## Section 4 — Install git (and Clone This Repo)

`git` is a version control tool. You need it to manage this codebase.

- **Windows:** Download from [https://git-scm.com/download/win](https://git-scm.com/download/win) and run the installer.
- **macOS:** Run `git --version` in Terminal — macOS will prompt you to install it automatically.
- **Linux:** `sudo apt install git`

If you received this project as a zip file, unzip it to a local folder. If it is in a git repository, clone it:

```bash
git clone <repository-url>
cd Gabriel_Infra
```

---

## Section 5 — Choose Your AWS Region

All resources in this project are created in a single AWS region. The default is `us-east-1` (Northern Virginia, USA), which has the best service availability and lowest prices.

**If you want to use a different region**, you need to update it in several places. Run this from the root of the project (replace `us-east-2` with your chosen region):

```bash
# macOS / Linux
sed -i '' 's/us-east-1/us-east-2/g' \
  bootstrap/variables.tf \
  environments/*/variables.tf \
  environments/*/terraform.tfvars \
  environments/*/backend.tf

# Windows PowerShell
Get-ChildItem -Recurse -Filter "*.tf","*.tfvars" | ForEach-Object {
  (Get-Content $_.FullName) -replace 'us-east-1','us-east-2' | Set-Content $_.FullName
}
```

**How to pick a region:** Choose the one geographically closest to your users. Common choices:
- `us-east-1` — US East (N. Virginia) — cheapest, most services
- `eu-west-1` — Europe (Ireland)
- `ap-southeast-1` — Asia Pacific (Singapore)

Find all region codes at [https://aws.amazon.com/about-aws/global-infrastructure/regions_az/](https://aws.amazon.com/about-aws/global-infrastructure/regions_az/)

---

## Section 6 — Domain Name & DNS

This project creates real HTTPS websites at `dev.theboateng.me`, `stage.theboateng.me`, and `prod.theboateng.me`. You need a real domain name you own.

### Option A — You already own a domain

Skip ahead to "What you need to do".

### Option B — Buy a domain through AWS Route 53

1. In the AWS Console, go to **Route 53** → **Registered domains** → **Register domain**.
2. Search for your desired domain, add it to cart, and complete purchase (~$12/year for a `.com`).
3. AWS automatically creates a hosted zone for it.

### Option C — Buy a domain elsewhere (GoDaddy, Namecheap, Google Domains, etc.)

Buy from wherever is cheapest. The domain itself does not need to be in AWS — you will just point its nameservers to AWS in a later step.

### What you need to do

The project is already configured for `theboateng.me` with subdomains `dev.theboateng.me`, `stage.theboateng.me`, and `prod.theboateng.me`. **No changes needed** — the domain is set and matches the Namecheap-registered domain.

If you ever need to use a different domain, run:

```bash
# macOS / Linux
sed -i '' 's/theboateng\.me/yourdomain.example/g' \
  bootstrap/variables.tf \
  environments/*/variables.tf \
  environments/*/terraform.tfvars
```

```powershell
# Windows PowerShell
Get-ChildItem -Recurse -Include "*.tf","*.tfvars" | ForEach-Object {
  (Get-Content $_.FullName) -replace 'theboateng\.me','yourdomain.example' | Set-Content $_.FullName
}
```

After running the command, open `environments/dev/terraform.tfvars` and verify the subdomain values look correct for your domain. They should now read `dev.yourdomain.example`, `stage.yourdomain.example`, `prod.yourdomain.example`.

> **You do not need to do anything at your registrar yet.** The Bootstrap step (Section 12) creates your Route 53 hosted zone, and only then do you update the nameservers at your registrar.

---

## Section 7 — Create an EC2 Key Pair

A key pair is an optional break-glass fallback for SSH access. This project uses AWS Systems Manager (SSM) for all normal admin access, so a key pair is not required — but it is worth having in case SSM is unavailable in an emergency.

A key pair named **`infratest`** has already been created and is pre-filled in all `terraform.tfvars` files. Keep the `.pem` file somewhere safe — AWS will not let you download it again.

If you ever need to create a new key pair:

1. In the AWS Console, go to **EC2** → (left menu) **Network & Security** → **Key Pairs**.
2. Click **Create key pair**.
3. Give it a name. Update `key_pair_name` in all three `terraform.tfvars` files to match.
4. Choose **RSA** format and **.pem** file type.
5. Click **Create key pair** — the `.pem` file downloads automatically.
6. **Move the `.pem` file to a safe place** (e.g. `~/.ssh/infratest.pem`). AWS will never show you this file again.

On macOS/Linux, set the correct permissions on the key file:

```bash
chmod 400 ~/.ssh/insight-edge-key.pem
```

---

## Section 8 — Elastic IP Quota

Removing the VPN solved the EIP quota problem. This project now uses only NAT Gateway EIPs:

| Environment | NAT Gateway EIPs | Total |
|-------------|:----------------:|:-----:|
| Dev | 1 | **1** |
| Staging | 1 | **1** |
| Prod (dual-AZ NAT) | 2 | **2** |
| **All three simultaneously** | | **4** |

Four is well within the default AWS quota of 5. You can run all three environments at the same time with no quota increase needed — nothing to do here.

---

## Section 9 — Set Up Alert Emails

This project sends you email alerts when things go wrong (high CPU, unhealthy servers, etc.) and when GuardDuty detects threats. You need at least one valid email address.

You will set `alert_emails` in each environment's `terraform.tfvars` file. For now, just decide which email address(es) to use. Good options:
- A personal Gmail address (fine for dev/staging)
- A team distribution list (recommended for prod)

> **After each `terraform apply`**, AWS sends a "Subscription Confirmation" email to every address in `alert_emails`. You **must click the link in that email** or you will receive zero alerts. Check spam if you don't see it.

Similarly, for GuardDuty alerts (which fire for HIGH/CRITICAL security threats), you will use the same emails in the bootstrap step via `budget_alert_emails`.

---

## Section 10 — Understand the File Structure

Before touching any files, here is what each folder does:

```
Gabriel_Infra/
├── bootstrap/              Run ONCE per AWS account. Creates the S3 bucket that
│                           stores Terraform's memory, plus account-wide security.
│
├── modules/                Reusable building blocks. You do NOT apply these directly.
│   ├── vpc/                Networking (subnets, routing, NAT gateway)
│   ├── security_groups/    Firewall rules
│   ├── alb/                Load balancer + HTTPS certificate
│   ├── waf/                Web Application Firewall
│   ├── ec2_app/            Application servers (Auto Scaling Group)
│   ├── (vpn/ module exists but is not used — admin access is via SSM)
│   ├── rds/                PostgreSQL database (primary + replica)
│   ├── s3/                 File storage + ALB access logs
│   ├── cognito/            User authentication
│   ├── route53/            DNS records
│   └── monitoring/         CloudWatch alarms + SNS alerts
│
└── environments/           One folder per environment. This is where you run
    ├── dev/                terraform apply. Each environment is completely
    ├── staging/            isolated — its own VPC, its own database, etc.
    └── prod/
```

---

## Section 11 — Fill In the Variable Files

Each environment has a `terraform.tfvars` file — this is where you fill in values specific to your deployment. Open each one and fill in the blanks.

**You need two values from the Bootstrap step before you can fill these in completely.** The Bootstrap step tells you what to put in `route53_zone_id`. For now, open each `terraform.tfvars` file and fill in only what you know:

### `environments/dev/terraform.tfvars`
### `environments/staging/terraform.tfvars`
### `environments/prod/terraform.tfvars`

The following values are **already pre-filled** in all three `terraform.tfvars` files — no changes needed:

| Field | Value | Source |
|-------|-------|--------|
| `project_name` | `insight-edge` | Pre-configured |
| `domain_name` | `theboateng.me` | Registered domain |
| `route53_zone_id` | `Z03874001XT5UX4ZUS33K` | From Bootstrap output |
| `key_pair_name` | `infratest` | EC2 key pair created in Section 7 |

The only field you still need to fill in before deploying each environment is:

```hcl
# At least one email address that will receive alerts
alert_emails = ["you@example.com"]
```

> **prod only:** `alert_emails` in prod is not optional — leave it empty and you get no notification when your production database is about to fill up.

---

## Section 12 — Configure the State Backends

Terraform stores a record of what it has created in an S3 bucket (the "state backend"). Each environment needs to know which S3 bucket to use.

All three `backend.tf` files are already configured with the correct account ID (`310688446551`) and use S3-native locking:

```hcl
terraform {
  backend "s3" {
    bucket       = "insight-edge-terraform-state-310688446551"
    key          = "dev/terraform.tfstate"   # staging/ and prod/ in the other files
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

No changes needed here. Bootstrap must be applied before `terraform init` will work in any environment (it creates the S3 bucket).

---

## Section 13 — Run Bootstrap (Once per AWS Account)

Bootstrap is a one-time setup that creates the infrastructure that Terraform itself needs:
- An S3 bucket to store Terraform state files
- A DynamoDB table for state locking (prevents two people applying at once)
- A Route 53 hosted zone for your domain
- Account-wide security: CloudTrail audit logging, GuardDuty threat detection, IAM password policy, default EBS encryption, and an AWS Budget alert

### Steps

Open a terminal, navigate to the project root folder, and run:

```bash
cd bootstrap

terraform init
```

You should see: `Terraform has been successfully initialized!`

Then run:

```bash
terraform plan
```

This previews everything Terraform will create. Read through it. If you see errors, check that your AWS CLI is configured correctly (Section 2B).

Then apply:

```bash
terraform apply \
  -var='budget_alert_emails=["you@example.com"]' \
  -var='monthly_budget_usd=500'
```

When prompted `Do you want to perform these actions?`, type `yes` and press Enter.

Bootstrap takes 1–3 minutes. When finished, you will see output like:

```
Outputs:

aws_account_id          = "123456789012"
route53_name_servers    = toset([
  "ns-1234.awsdns-12.com",
  "ns-456.awsdns-34.net",
  "ns-789.awsdns-56.org",
  "ns-012.awsdns-78.co.uk",
])
route53_zone_id         = "Z1234ABC5678DEF"
state_bucket_name       = "my-project-terraform-state-123456789012"
```

**Bootstrap is already complete for this project.** The outputs have been recorded — `route53_zone_id` and `key_pair_name` are pre-filled in all `terraform.tfvars` files. The nameservers for `theboateng.me` must still be pointed at Route 53 in Namecheap if not done already.

For reference, the outputs look like this:

### After Bootstrap — Update Nameservers at Your Registrar

Your domain's DNS is now managed by AWS Route 53, but your domain registrar still points to the old nameservers. You need to update them.

Log in to wherever you bought your domain and find the "Nameservers" or "DNS" settings. Replace whatever is there with the four `ns-xxx.awsdns-xx` values from the Bootstrap output above. The exact steps depend on your registrar:

| Registrar | Where to find it |
|-----------|-----------------|
| GoDaddy | My Products → Manage → DNS → Nameservers → Change → Custom |
| Namecheap | Domain List → Manage → Nameservers → Custom DNS |
| Google Domains / Squarespace | DNS → Custom name servers |
| Cloudflare | Websites → your domain → DNS → Nameservers |

After saving, DNS propagation takes **15 minutes to 2 hours** (occasionally up to 48 hours). Verify propagation with:

```bash
# macOS / Linux
dig NS yourdomain.example +short

# Windows PowerShell
Resolve-DnsName yourdomain.example -Type NS
```

The output should show the four `awsdns` nameservers. **Do not proceed to deploy environments until you see this.**

> **Why this matters:** The HTTPS certificate validation in each environment uses DNS to verify you own the domain. If nameservers aren't pointing to Route 53 yet, `terraform apply` will hang for 10 minutes and then fail.

### After Bootstrap — Fill In the Remaining Blanks

Now you have the values you need to complete setup:

All values are already pre-filled. The only remaining action is confirming Namecheap nameservers point to Route 53 (see "After Bootstrap — Update Nameservers" above).

---

## Section 14 — Deploy the Environments

Deploy **in order**: dev first, then staging, then prod. Verify each works before moving to the next.

> **How long does it take?** Each environment takes **15–25 minutes**. RDS (the database) is the slowest part. Do not interrupt the process.

### Deploy Dev

```bash
cd environments/dev

terraform init
```

Expected: `Terraform has been successfully initialized!`

> If you see `Error: Failed to get existing workspaces: S3 bucket does not exist`, you either haven't run Bootstrap yet or the `<ACCOUNT_ID>` in `backend.tf` is still the placeholder. Fix those first.

```bash
terraform plan
```

Read the output. It should show a large number of resources to be created (VPC, subnets, ALB, EC2 instances, RDS, etc.). If it shows errors, fix them before applying.

```bash
terraform apply
```

Type `yes` when prompted. Watch the output. Terraform will print each resource as it's created. Near the end, RDS creation takes 10–15 minutes — this is normal.

When finished, you'll see outputs like:

```
alb_url    = "https://dev.theboateng.me"
db_secret_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:..."
```

**Immediately after apply:**
- Check your email and click **"Confirm subscription"** from AWS Notifications — without this, you receive no alerts.

### Deploy Staging

```bash
cd ../staging
terraform init
terraform plan
terraform apply
```

### Deploy Prod

```bash
cd ../prod
terraform init
terraform plan    # review carefully before applying to prod
terraform apply
```

Prod has `deletion_protection = true` on the database and load balancer. This prevents accidental deletion.

---

## Section 15 — Post-Deploy Required Actions

Do these immediately after each environment finishes applying:

### 1. Confirm SNS Email Subscriptions

Check the inbox for every address in `alert_emails`. You will receive an email with subject **"AWS Notification - Subscription Confirmation"**. Click the **Confirm subscription** link inside. You have 72 hours before it expires.

If you miss it or it expires:
```bash
# From the environment's directory
aws sns list-subscriptions-by-topic \
  --topic-arn $(terraform output -raw alerts_topic_arn)
```
Delete unconfirmed subscriptions and re-apply to recreate them.

### 2. Verify EC2 Access via SSM Session Manager

Confirm that SSM is working before you need it:

```bash
cd environments/dev

INSTANCE=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $(terraform output -raw asg_name) \
  --query 'AutoScalingGroups[0].Instances[0].InstanceId' \
  --output text)

aws ssm start-session --target $INSTANCE
```

You should get a shell prompt on the instance. Type `exit` to close. If it fails, wait 2–3 minutes for the SSM agent to finish starting, then try again.

### 3. Verify the ALB is Reachable

Open `https://dev.theboateng.me` in a browser. You should see a page that says **"This is the dev environment"**. You can also verify with curl:

```bash
curl -I https://dev.theboateng.me        # should return HTTP/2 200
curl https://dev.theboateng.me/health    # should return: OK
```

An SSL handshake failure means DNS hasn't propagated yet or the ACM certificate isn't validated — wait a few minutes and retry. A 502 "Bad Gateway" means the EC2 instances haven't passed health checks yet — wait for the ASG warm-up (about 5 minutes after `apply` completes).

### 4. Retrieve Database Credentials

Your database password is stored in AWS Secrets Manager and never appears in any config file. Retrieve it:

```bash
aws secretsmanager get-secret-value \
  --secret-id $(terraform output -raw db_secret_arn) \
  --query SecretString \
  --output text
```

Expected output (formatted for readability):

```json
{
  "username": "dbadmin",
  "password": "randomGeneratedPassword",
  "engine": "postgres",
  "host": "my-project-dev-primary.xxxxx.us-east-1.rds.amazonaws.com",
  "port": 5432,
  "dbname": "appdb",
  "ro_host": "my-project-dev-replica.xxxxx.us-east-1.rds.amazonaws.com"
}
```

Use `host` for read-write queries and `ro_host` for read-only queries.

### 5. Deploy Your Application

The infrastructure creates servers but does not put your application on them. You need to deploy your application code separately. Common methods:

- **AWS Systems Manager Session Manager** (no SSH key needed):
  ```bash
  # Get an instance ID from the ASG
  INSTANCE=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names $(terraform output -raw asg_name) \
    --query 'AutoScalingGroups[0].Instances[0].InstanceId' \
    --output text)
  
  # Open a terminal session on that instance
  aws ssm start-session --target $INSTANCE
  ```

- **SSH via key pair (break-glass)**: If SSM is unavailable, you can SSH directly to the private IP from another EC2 instance in the same VPC. This requires the `.pem` key file from Section 7.

- **SSM SendCommand from local**: Run the deploy loop shown above from your laptop.

Your app must:
- Listen on port `8080` (or whatever you set in `app_port`)
- Respond with HTTP 200 to GET requests at `/health` (or whatever you set in `health_check_path`)

The ALB will show 503 errors until the health check passes.

### 6. Verify CloudWatch Alarms

1. In the AWS Console, go to **CloudWatch** → **Alarms**.
2. All alarms should show **OK** or **Insufficient Data** status (not **ALARM**).
3. "Insufficient Data" is normal until your application is running and generating metrics.

---

## Section 16 — Cost Expectations

Setting a budget alert at `$500/month` (or `$1,500` if running all three environments) gives you early warning before bills get large.

| Environment | Monthly cost (approx.) |
|-------------|------------------------|
| Dev | ~$95 |
| Staging | ~$166 |
| Prod | ~$331 (includes second NAT GW for HA) |
| Account-wide (CloudTrail, GuardDuty) | ~$7 |
| **Total (all three)** | **~$599/month** |

> **Tip:** Tear down dev and staging when you're not actively using them. NAT Gateways cost ~$33/month each even when idle. `terraform destroy` on an environment takes about 10 minutes.

Cost is highest in the first month because of RDS initial setup. Numbers are for `us-east-1` on-demand pricing — Reserved Instances (1-year commitment) reduce compute costs by ~40%.

---

## Section 17 — Troubleshooting Common Problems

| What you see | Likely cause | Fix |
|---|---|---|
| `apply` hangs at ACM certificate validation for >5 min | Domain nameservers not yet pointing to Route 53 | Wait for DNS propagation. Run `Resolve-DnsName theboateng.me -Type NS` in PowerShell — should show AWS nameservers. Re-run `terraform apply` once propagation is confirmed. |
| `Error: EIP quota exceeded` | Unexpected — this architecture uses only 4 EIPs total. Check that no other resources in the account are holding EIPs. Run `aws ec2 describe-addresses` to see all allocated EIPs. |
| `Error: Failed to get existing workspaces: InvalidBucketName` | Bootstrap not run yet, or `backend.tf` still has `<ACCOUNT_ID>` placeholder | Run `cd bootstrap && terraform apply` first. The `backend.tf` files in this project already have the correct account ID pre-filled. |
| `Error: Cycle: module.security_groups.aws_security_group.alb, module.security_groups.aws_security_group.app` | Security groups referencing each other in inline rules | Already fixed in this project — the cross-references use `aws_security_group_rule` resources instead of inline blocks. If this appears, check `modules/security_groups/main.tf`. |
| `Error: InvalidParameterValue: Value (...) for parameter GroupDescription is invalid. Character sets beyond ASCII are not supported` | Security group description contains a non-ASCII character (e.g. an em dash `—`) | Already fixed — all security group descriptions use only ASCII characters. If this appears after editing descriptions, replace any `—` with `-`. |
| `Error: cannot use immediate apply method for static parameter` | RDS parameter group has `shared_preload_libraries` without `apply_method = "pending-reboot"` | Already fixed in `modules/rds/main.tf`. The static parameter now includes `apply_method = "pending-reboot"`. |
| `Error: DBParameterGroupAlreadyExists` | A previous failed apply created the parameter group but Terraform lost track of it | Run `terraform state rm module.rds.aws_db_parameter_group.main` then `terraform apply`. |
| `Error: Your query returned no results` on `data.aws_ami.ubuntu` | AMI name filter pattern is wrong | Already fixed — correct pattern is `ubuntu-jammy-22.04-amd64-server-*` (not `ubuntu-22.04-amd64-server-*`). |
| `SessionManagerPlugin is not found` when running `aws ssm start-session` | AWS SSM Session Manager plugin not installed on your laptop | Download and install from: `https://s3.amazonaws.com/session-manager-downloads/plugin/latest/windows/SessionManagerPluginSetup.exe`. Restart terminal after install. |
| `An error occurred (TargetNotConnected)` on `aws ssm start-session` | Instance still starting, or user_data still running | Wait 10–15 minutes after launch (user_data runs `apt-get upgrade` which is slow). Check `aws ec2 get-console-output --instance-id <id> --output text` to see progress. |
| ALB targets show **unhealthy** | nginx not running yet (user_data still in progress), or user_data failed | Wait 10–15 minutes. If still unhealthy, check console output with the command above. The last line of `/var/log/user-data.log` should say "Bootstrap complete". |
| ALB returns 502 | Instances failing health checks — nginx not yet running | Wait for instances to finish initializing. Check EC2 console → Target Groups → Targets tab for health status. |
| ALB returns 503 immediately after deploy | App not running on EC2 instances yet | The landing page nginx serves on port 8080 handles this. A 503 means no healthy instances at all — check ASG has at least 1 instance in service. |
| SSM Session Manager opens but commands hang | Instance is under high CPU load or the SSM agent crashed | Wait 1–2 minutes; try a new session. Check CloudWatch for the CPU high alarm. |
| No alarm emails after deploy | SNS subscription not confirmed | Check inbox (including spam) for "AWS Notification - Subscription Confirmation". Click the link. |
| `ResourceAlreadyExistsException: The specified log group already exists` | CloudWatch log group left over from a previous destroy (common when re-applying dev after a destroy) | Run `terraform import module.vpc.aws_cloudwatch_log_group.vpc_flow "/aws/vpc/insight-edge-dev/flow-logs"` then `terraform apply`. |
| `Error: deleting S3 Bucket: BucketNotEmpty` on `terraform destroy` | S3 bucket has versioned objects (e.g. ALB access logs). Versioned buckets must be fully emptied before deletion. | In the AWS Console: S3 → bucket → **Empty** button → confirm. Then re-run `terraform destroy`. Already fixed in code via `force_destroy = true`. |
| `terraform destroy` fails on prod | Deletion protection on ALB and RDS | In the AWS Console, disable deletion protection on the RDS instance and ALB manually, then run `terraform destroy`. |
| RDS replica creation hangs >20 minutes | RDS primary is running its first automated backup | This is normal. Wait up to 30 minutes total. |
| `Cognito user pool domain is already taken` | Another account already registered your `project_name-env` prefix | Change `project_name` in `terraform.tfvars` to something more unique (e.g. add your initials or a number). |
| `apply` completes but `https://dev.theboateng.me` times out | DNS not propagated yet, or instances still initializing | Wait 5 minutes and retry. If the URL resolves but returns 502, the instances are up but nginx is still starting — wait another 5 minutes. |

---

## Section 18 — Clean Teardown

Destroy environments in reverse order. **Destroying Bootstrap last.** Destroying Bootstrap before the environments makes the environments' state files orphaned and unrecoverable.

```bash
# 1. Prod (must remove deletion protection first)
cd environments/prod
# Edit environments/prod/main.tf:
#   - In module "alb":  enable_deletion_protection = false
#   - In module "rds":  (handled automatically since it reads var.environment)
# But for RDS, since deletion_protection is set via ternary on var.environment == "prod",
# you must temporarily change local.environment or use a -var override:
terraform apply -var='project_name=insight-edge'  # re-apply with deletion protection logic adjusted
# OR just go to RDS in the console, modify the instance to disable deletion protection, then:
terraform destroy

# 2. Staging
cd ../staging
terraform destroy

# 3. Dev
cd ../dev
terraform destroy

# 4. Bootstrap (last — destroys Route 53 zone, CloudTrail, GuardDuty, state bucket)
# WARNING: The state bucket has prevent_destroy=true. Remove that block from
# bootstrap/main.tf before destroying:
cd ../../bootstrap
# Edit bootstrap/main.tf and remove the lifecycle { prevent_destroy = true } block
# from aws_s3_bucket.terraform_state, then:
terraform destroy
```

> **Note:** The DynamoDB locks table also has `prevent_destroy = true`. Remove its lifecycle block too before running `terraform destroy` on bootstrap.

---

## Section 19 — Optional Hardening (After Everything Works)

Once your environments are running, consider adding these for production readiness:

| Enhancement | Why | Effort |
|-------------|-----|--------|
| **Amazon SES for Cognito email** | Default Cognito email is capped at 50/day — SES handles production volumes | Medium |
| **Secrets Manager rotation** | Automatically rotates the database password on a schedule | Medium |
| **VPC Interface Endpoints** (SSM, Secrets Manager) | All AWS API calls stay inside the VPC, never touching the internet | Low |
| **AWS Config + Conformance Packs** | Detects configuration drift against CIS or PCI-DSS benchmarks | Medium |
| **GitHub OIDC IAM role** | Lets GitHub Actions deploy to AWS without storing long-lived credentials | Low |
| **CloudFront in front of ALB** | Adds edge caching, DDoS absorption, and global performance | High |
| **AWS Inspector** | Scans EC2 and RDS for known CVEs automatically | Low |
| **KMS Customer-Managed Keys** | Stronger key isolation than the default AWS-managed keys | Low |
| **Multi-region DR** | Replicate prod to a second region for disaster recovery | Very High |
