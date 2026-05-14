terraform {
  backend "s3" {
    # Replace <ACCOUNT_ID> with the value from `terraform output aws_account_id` in bootstrap/
    bucket       = "insight-edge-terraform-state-310688446551"
    key          = "staging/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
