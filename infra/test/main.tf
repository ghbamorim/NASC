module "common" {
  source = "../modules/common"

  environment = "test"
  vpc_cidr    = "10.1.0.0/16"
  db_password = var.db_password
}