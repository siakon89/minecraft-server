module "efs" {
  source  = "terraform-aws-modules/efs/aws"
  version = "~> 1.8"

  # File system
  name           = "minecraft-volume"
  creation_token = "minecraft-volume"
  encrypted      = true
  kms_key_arn    = module.kms.key_arn

  # File system policy
  attach_policy                      = true
  bypass_policy_lockout_safety_check = false

  policy_statements = [
    {
      sid = "Example"
      actions = [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite",
        "elasticfilesystem:ClientRootAccess",
        "elasticfilesystem:DescribeFileSystems"
      ]
      principals = [
        {
          type        = "AWS"
          identifiers = [module.ecs.task_exec_iam_role_arn]
        }
      ]
    }
  ]

  # Mount targets / security group
  mount_targets              = { for k, v in zipmap(module.vpc.azs, module.vpc.public_subnets) : k => { subnet_id = v } }
  security_group_description = "EFS security group for minecraft server"
  security_group_vpc_id      = module.vpc.vpc_id

  security_group_rules = {
    vpc = {
      # relying on the defaults provided for EFS/NFS (2049/TCP + ingress)
      description = "NFS ingress from VPC public subnets"
      cidr_blocks = module.vpc.public_subnets_cidr_blocks
    }
  }

  access_points = {
    vanilla_minecraft = {
      posix_user = {
        gid = 1000
        uid = 1000
      }
      root_directory = {
        path = "/vanilla"
        creation_info = {
          owner_gid   = 1000
          owner_uid   = 1000
          permissions = "755"
        }
      }
    }
  }

  # Backup policy
  enable_backup_policy = false
  # Replication configuration
  create_replication_configuration = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 1.0"

  aliases               = ["efs/minecraft-volume"]
  description           = "EFS customer managed key"
  enable_default_policy = true
}
