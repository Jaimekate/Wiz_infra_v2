data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 5.0"

  name = "${var.name}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets  = ["10.60.0.0/24", "10.60.1.0/24"]
  private_subnets = ["10.60.2.0/24", "10.60.3.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  # subnet tags for ALB controller discovery
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = {
    "kubernetes.io/cluster/${var.name}-eks" = "shared"
  }
}
