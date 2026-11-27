locals {
  name_prefix = "nasc-${var.environment}"

  public_subnet_cidr    = cidrsubnet(var.vpc_cidr, 8, 1)
  private_a_subnet_cidr = cidrsubnet(var.vpc_cidr, 8, 2)
  private_b_subnet_cidr = cidrsubnet(var.vpc_cidr, 8, 3)

  private_nat_cidr = cidrsubnet(var.vpc_cidr, 7, 1)
}