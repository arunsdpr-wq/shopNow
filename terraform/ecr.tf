# ECR Repositories
resource "aws_ecr_repository" "shopnow" {
  for_each = toset(var.ecr_repositories)

  repository_name = "${var.project_name}/${each.value}"

  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = var.ecr_image_scan_on_push
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ecr.arn
  }

  tags = merge(
    local.environment_tag,
    {
      Name       = "${var.project_name}-${each.value}-repo"
      Repository = each.value
    }
  )
}

# Lifecycle policy for ECR repositories
resource "aws_ecr_lifecycle_policy" "shopnow" {
  for_each = aws_ecr_repository.shopnow

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "release"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Remove untagged images after ${var.ecr_image_retention_days} days"
        selection = {
          tagStatus             = "untagged"
          countType             = "sinceImagePushed"
          countUnit             = "days"
          countNumber           = var.ecr_image_retention_days
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Repository access policy to allow pulling images
resource "aws_ecr_repository_policy" "shopnow" {
  for_each = aws_ecr_repository.shopnow

  repository = each.value.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPull"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.node.name}"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeImages",
          "ecr:ListImages"
        ]
      }
    ]
  })
}

# KMS Key for ECR encryption
resource "aws_kms_key" "ecr" {
  description             = "KMS key for ECR repository encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = merge(
    local.environment_tag,
    {
      Name = "${var.project_name}-${var.environment}-ecr-key"
    }
  )
}

resource "aws_kms_alias" "ecr" {
  name          = "alias/${var.project_name}-${var.environment}-ecr"
  target_key_id = aws_kms_key.ecr.key_id
}
