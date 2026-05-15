# Bootstrap

One-time setup that the per-environment stacks depend on:

1. **S3 bucket** — versioned + encrypted, holds Terraform state for every environment
2. **DynamoDB table** — state locking so two engineers can't apply at the same time
3. **Route 53 hosted zone** — shared across dev/staging/prod for the project domain

## Run

```bash
terraform init
terraform apply
```

## Outputs you need to record

```bash
terraform output state_bucket_name      # for environments/*/backend.tf
terraform output dynamodb_table_name    # for environments/*/backend.tf
terraform output route53_zone_id        # for environments/*/terraform.tfvars
terraform output route53_name_servers   # paste into your domain registrar
terraform output aws_account_id
```

## After running

1. At your domain registrar, replace the NS records for your domain (pre-configured as `insight-edgecs.com` — update to your actual domain first per REQUIREMENTS.md Section 6) with the four name servers from `route53_name_servers`. Allow up to 48 hours to propagate (usually <1h).
2. ~~In each `../environments/*/backend.tf`, replace `<ACCOUNT_ID>` with the account ID.~~ Already done — account ID `310688446551` is pre-filled in all backend files.
3. In each `../environments/*/terraform.tfvars`, paste in `route53_zone_id`.

## Don't destroy this stack

The S3 state bucket has `prevent_destroy = true`. If you really need to tear it down, you must first migrate every environment off the S3 backend (or destroy them), then remove the lifecycle block, then `terraform destroy`.
