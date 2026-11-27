terraform {
  backend "s3" {
    key          = "test/terraform.tfstate"
    use_lockfile = true
  }
}