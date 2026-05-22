module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access

  # VPC and Networking
  vpc_id     = aws_vpc.main.id
  subnet_ids = concat(aws_subnet.private[*].id, aws_subnet.public[*].id)

  # IAM Roles
  cluster_iam_role_arn = aws_iam_role.cluster.arn

  # Cluster encryption
  cluster_encryption_config = {
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }

  # Logging
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_retention_in_days = var.log_retention_days
  cloudwatch_log_group_kms_key_id = aws_kms_key.eks.arn

  # Node Groups
  eks_managed_node_groups = {
    general = {
      name = "${var.project_name}-${var.environment}-node-group"

      # Capacity
      desired_size = var.node_group_desired_size
      min_size     = var.node_group_min_size
      max_size     = var.node_group_max_size

      # Instance Types
      instance_types = var.node_instance_types
      disk_size      = var.node_disk_size

      # IAM Role
      iam_role_arn = aws_iam_role.node.arn

      # Security Groups
      vpc_security_group_ids = [aws_security_group.node.id]

      # Update Strategy
      update_config = {
        max_unavailable_percentage = 33
      }

      # Taints
      taints = []

      # Labels
      labels = {
        Environment = var.environment
        Type        = "general"
      }

      tags = merge(
        local.environment_tag,
        {
          NodeGroup = "general"
        }
      )
    }
  }

  # Cluster tags
  tags = merge(
    local.environment_tag,
    {
      ClusterName = local.cluster_name
    }
  )
}

# KMS Key for EKS encryption
resource "aws_kms_key" "eks" {
  description             = "KMS key for EKS cluster encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = merge(
    local.environment_tag,
    {
      Name = "${var.project_name}-${var.environment}-eks-key"
    }
  )
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.project_name}-${var.environment}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

# CloudWatch Log Group for EKS Cluster Logs
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${local.cluster_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.eks.arn

  tags = merge(
    local.environment_tag,
    {
      Name = "${var.project_name}-${var.environment}-eks-logs"
    }
  )
}

# OIDC Provider for EKS
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [module.eks.oidc_provider_thumbprint]
  url             = module.eks.oidc_provider_arn

  tags = merge(
    local.environment_tag,
    {
      Name = "${var.project_name}-${var.environment}-oidc-provider"
    }
  )
}

# EBS CSI Driver Add-on
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = data.aws_eks_addon_version.ebs_csi_driver.version
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn

  tags = local.environment_tag
}

data "aws_eks_addon_version" "ebs_csi_driver" {
  addon_name           = "aws-ebs-csi-driver"
  kubernetes_version   = var.cluster_version
  most_recent          = true
}

# VPC CNI Add-on
resource "aws_eks_addon" "vpc_cni" {
  cluster_name    = module.eks.cluster_name
  addon_name      = "vpc-cni"
  addon_version   = data.aws_eks_addon_version.vpc_cni.version
  preserve        = true
  resolve_conflicts = "OVERWRITE"

  tags = local.environment_tag
}

data "aws_eks_addon_version" "vpc_cni" {
  addon_name           = "vpc-cni"
  kubernetes_version   = var.cluster_version
  most_recent          = true
}

# CoreDNS Add-on
resource "aws_eks_addon" "coredns" {
  cluster_name    = module.eks.cluster_name
  addon_name      = "coredns"
  addon_version   = data.aws_eks_addon_version.coredns.version
  resolve_conflicts = "OVERWRITE"

  tags = local.environment_tag
}

data "aws_eks_addon_version" "coredns" {
  addon_name           = "coredns"
  kubernetes_version   = var.cluster_version
  most_recent          = true
}

# kube-proxy Add-on
resource "aws_eks_addon" "kube_proxy" {
  cluster_name    = module.eks.cluster_name
  addon_name      = "kube-proxy"
  addon_version   = data.aws_eks_addon_version.kube_proxy.version
  resolve_conflicts = "OVERWRITE"

  tags = local.environment_tag
}

data "aws_eks_addon_version" "kube_proxy" {
  addon_name           = "kube-proxy"
  kubernetes_version   = var.cluster_version
  most_recent          = true
}

# Storage Class for EBS volumes
resource "kubernetes_storage_class" "ebs_gp3" {
  depends_on = [module.eks]

  metadata {
    name = "gp3-ssd"
  }

  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"

  parameters = {
    type       = "gp3"
    iops       = 3000
    throughput = 125
    encrypted  = true
  }

  allow_volume_expansion = true
}

# Default Storage Class
resource "kubernetes_storage_class" "ebs_gp3_default" {
  depends_on = [module.eks]

  metadata {
    name = "gp3-ssd-default"
  }

  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"

  parameters = {
    type       = "gp3"
    iops       = 3000
    throughput = 125
    encrypted  = true
  }

  allow_volume_expansion = true
}
