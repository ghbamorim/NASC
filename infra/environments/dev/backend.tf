terraform {
  backend "s3" {
    bucket       = "nasc-terraform-state-242627333067-us-east-2"
    key          = "dev/terraform.tfstate"
    region       = "us-east-2"
    use_lockfile = true
    encrypt      = true
  }
}