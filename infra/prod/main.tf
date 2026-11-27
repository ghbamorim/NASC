module "common" {
  source = "../modules/common"

  environment = "prod"
  vpc_cidr    = "10.2.0.0/16"
  db_password = var.db_password
}