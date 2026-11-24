terraform {
  backend "s3" {
    key          = "dev/terraform.tfstate"
    use_lockfile = true
  }
}