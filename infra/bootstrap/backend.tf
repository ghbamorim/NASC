terraform {
  backend "s3" {
    key          = "bootstrap/terraform.tfstate"
    profile      = "terraform-admin"
    use_lockfile = true
  }
}