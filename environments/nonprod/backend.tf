terraform {
  backend "s3" {
    bucket       = "insight-edge-terraform-state-310688446551"
    key          = "nonprod/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
