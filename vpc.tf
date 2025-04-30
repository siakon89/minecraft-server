module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.19.0"

  name = "minecraft-vpc"
  cidr = local.cidr

  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  # Enable NAT Gateway for private subnets
  enable_nat_gateway = true
  single_nat_gateway = true # Use a single NAT Gateway to save costs

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}