module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.12"

  cluster_name = "minecraft-servers"

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/minecraft-servers"
      }
    }
  }

  fargate_capacity_providers = {
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }

  services = {
    minecraft-vanilla = {
      cpu    = 2048
      memory = 4096

      # Enable execute command
      enable_execute_command = true

      volume = [
        {
          name = "minecraft-storage"

          efs_volume_configuration = {
            file_system_id     = module.efs.id
            transit_encryption = "ENABLED"
            root_directory     = "/"
            authorization_config = {
              iam             = "ENABLED"
              access_point_id = module.efs.access_points["vanilla_minecraft"].id
            }
          }
        }
      ]

      # Move to public subnets
      subnet_ids       = module.vpc.public_subnets
      assign_public_ip = true

      # Configure deployment strategy
      deployment_circuit_breaker = {
        enable   = true
        rollback = true
      }
      deployment_controller = {
        type = "ECS"
      }
      desired_count                      = 1
      deployment_minimum_healthy_percent = 0
      deployment_maximum_percent         = 100

      # Use the dedicated security group
      security_group_ids = [aws_security_group.ecs_service.id]

      # add access to EFS and KMS in the task role
      tasks_iam_role_policies = {
        efs_access = aws_iam_policy.efs_access_policy.arn
        kms_access = aws_iam_policy.efs_kms_access_policy.arn
        ssm_access = aws_iam_policy.ssm_session_manager_policy.arn
      }

      # Container definition(s)
      container_definitions = {
        minecraft-vanilla-task = {
          cpu    = 2048
          memory = 4096
          image  = "itzg/minecraft-server:latest"

          port_mappings = [
            {
              name          = "minecraft-vanilla-container"
              containerPort = local.container_port
              hostPort      = local.container_port
              protocol      = "tcp"
            }
          ]

          environment = [
            {
              name  = "EULA"
              value = "TRUE"
            },
            {
              name  = "WHITELIST"
              value = local.whitelist_list
            },
            {
              name  = "DIFFICULTY"
              value = local.difficulty
            },
            {
              name  = "ECS_ENABLE_CONTAINER_METADATA"
              value = "true"
            }
          ]

          mount_points = [
            {
              sourceVolume  = "minecraft-storage"
              containerPath = "/data"
              readOnly      = false
            }
          ]

          # Example image used requires access to write to root filesystem
          readonly_root_filesystem = false
          memory_reservation       = 100

          # Enable SSM Session Manager
          enable_execute_command = true
        }
      }
    }
  }

  # Create task execution role and attach policies for EFS
  create_task_exec_iam_role = true
  task_exec_iam_role_name   = "minecraft-exec-role"
  task_exec_iam_role_policies = {
    efs_access = aws_iam_policy.efs_access_policy.arn
    kms_access = aws_iam_policy.efs_kms_access_policy.arn
    ssm_access = aws_iam_policy.ssm_session_manager_policy.arn
  }

  tags = {
    Environment = "Development"
    Project     = "Minecraft"
  }
}

# Create a dedicated security group for the ECS service
resource "aws_security_group" "ecs_service" {
  name        = "minecraft-ecs-service-sg"
  description = "Security group for Minecraft ECS service"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = local.container_port
    to_port     = local.container_port
    protocol    = "tcp"
    description = "Minecraft port from internet"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    description     = "NFS Port"
    security_groups = [module.efs.security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Allow all outbound traffic"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "minecraft-ecs-service-sg"
    Environment = "Development"
    Project     = "Minecraft"
  }
}

# Create Elastic IP for the Minecraft server
resource "aws_eip" "minecraft" {
  domain = "vpc"
  tags = {
    Name        = "minecraft-server-eip"
    Environment = "Development"
    Project     = "Minecraft"
  }
}

# Associate the Elastic IP with the ECS task's ENI
resource "aws_eip_association" "minecraft" {
  allocation_id = aws_eip.minecraft.id
  network_interface_id = module.ecs.services["minecraft-vanilla"].network_configuration[0].network_interface_id
}

