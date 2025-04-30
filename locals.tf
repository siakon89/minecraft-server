locals {
  region = "eu-central-1"

  # Container
  container_port = 25565

  # Minecraft related
  whitelist_list = "<your Minecraft Username>"
  difficulty     = "hard"

  # VPC
  cidr            = "10.168.1.0/26"
  private_subnets = ["10.168.1.0/28", "10.168.1.16/28"]
  public_subnets  = ["10.168.1.32/28", "10.168.1.48/28"]
  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
}