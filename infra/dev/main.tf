module "common" {
  source = "../modules/common"

  environment = "dev"
  vpc_cidr    = "10.0.0.0/16"
  db_password = var.db_password
}