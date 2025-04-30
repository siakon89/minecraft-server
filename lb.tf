module "nlb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.16"

  name = "minecraft-nlb"

  load_balancer_type = "network"

  vpc_id                     = module.vpc.vpc_id
  subnets                    = module.vpc.public_subnets
  enable_deletion_protection = false
  create_security_group      = false
  security_groups            = [aws_security_group.nlb.id]

  listeners = {
    minecraft = {
      port     = local.container_port
      protocol = "TCP"
      forward = {
        target_group_key = "minecraft-vanilla"
      }
    }
  }

  target_groups = {
    minecraft-vanilla = {
      name              = "minecraft-vanilla"
      protocol          = "TCP"
      port              = local.container_port
      target_type       = "ip"
      create_attachment = false
      health_check = {
        enabled             = true
        interval            = 30
        healthy_threshold   = 3
        unhealthy_threshold = 3
        protocol            = "TCP"
        timeout             = 10
      }
    }
  }


  tags = {
    Environment = "Development"
    Project     = "Example"
  }
}

resource "aws_security_group" "nlb" {
  name        = "minecraft-nlb-sg"
  description = "Security group for Minecraft NLB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = local.container_port
    to_port     = local.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Minecraft server port"
  }

  egress {
    from_port   = local.container_port
    to_port     = local.container_port
    protocol    = "tcp"
    description = "Minecraft port to VPC"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  tags = {
    Name        = "minecraft-nlb-sg"
    Environment = "Development"
    Project     = "Example"
  }
} 