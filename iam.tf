resource "aws_iam_policy" "efs_access_policy" {
  name        = "EFSAccessPolicy"
  description = "Policy to allow ECS tasks to access EFS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess",
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:DescribeAccessPoints"
        ]
        Resource = [
          module.efs.arn,
          module.efs.access_points["vanilla_minecraft"].arn
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "efs_kms_access_policy" {
  name        = "EFSKMSAccessPolicy"
  description = "Policy to allow ECS tasks to access the KMS key for EFS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = module.kms.key_arn // Replace with your KMS key ARN
      }
    ]
  })
}

resource "aws_iam_policy" "ssm_session_manager_policy" {
  name        = "SSMSessionManagerPolicy"
  description = "Policy to allow ECS tasks to use SSM Session Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}
