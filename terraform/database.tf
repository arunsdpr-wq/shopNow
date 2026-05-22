# Optional: DocumentDB (MongoDB-compatible) RDS Configuration
# Set enable_rds_mongodb = true in terraform.tfvars to enable this

resource "aws_db_subnet_group" "mongodb" {
  count       = var.enable_rds_mongodb ? 1 : 0
  name        = "${var.project_name}-${var.environment}-docdb-subnet-group"
  subnet_ids  = aws_subnet.private[*].id
  description = "Subnet group for DocumentDB"

  tags = merge(
    local.environment_tag,
    {
      Name = "${var.project_name}-${var.environment}-docdb-subnet-group"
    }
  )
}

resource "aws_docdb_cluster" "mongodb" {
  count                           = var.enable_rds_mongodb ? 1 : 0
  cluster_identifier              = "${var.project_name}-${var.environment}-docdb"
  engine                          = "docdb"
  engine_version                  = var.mongodb_engine_version
  master_username                 = "admin"
  master_password                 = random_password.docdb_password[0].result
  backup_retention_period         = 7
  preferred_backup_window         = "07:00-09:00"
  skip_final_snapshot             = var.environment == "dev" ? true : false
  final_snapshot_identifier       = "${var.project_name}-${var.environment}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  storage_encrypted               = true
  kms_key_id                      = aws_kms_key.docdb[0].arn
  db_subnet_group_name            = aws_db_subnet_group.mongodb[0].name
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.default[0].name
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowlog"]
  vpc_security_group_ids          = [aws_security_group.database.id]

  tags = merge(
    local.environment_tag,
    {
      Name = "${var.project_name}-${var.environment}-docdb"
    }
  )

  depends_on = [aws_security_group.database]
}

resource "aws_docdb_cluster_instance" "mongodb" {
  count              = var.enable_rds_mongodb ? 1 : 0
  identifier         = "${var.project_name}-${var.environment}-docdb-instance"
  cluster_identifier = aws_docdb_cluster.mongodb[0].id
  instance_class     = var.mongodb_instance_class
  engine             = "docdb"
  auto_minor_version_upgrade = false

  tags = merge(
    local.environment_tag,
    {
      Name = "${var.project_name}-${var.environment}-docdb-instance"
    }
  )
}

resource "aws_docdb_cluster_parameter_group" "default" {
  count       = var.enable_rds_mongodb ? 1 : 0
  family      = "docdb5.0"
  name        = "${var.project_name}-${var.environment}-docdb-param-group"
  description = "DocumentDB parameter group for ShopNow"

  tags = merge(
    local.environment_tag,
    {
      Name = "${var.project_name}-${var.environment}-docdb-param-group"
    }
  )
}

# Random password for DocumentDB
resource "random_password" "docdb_password" {
  count   = var.enable_rds_mongodb ? 1 : 0
  length  = 16
  special = true
}

# KMS Key for DocumentDB encryption
resource "aws_kms_key" "docdb" {
  count                   = var.enable_rds_mongodb ? 1 : 0
  description             = "KMS key for DocumentDB encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = merge(
    local.environment_tag,
    {
      Name = "${var.project_name}-${var.environment}-docdb-key"
    }
  )
}

resource "aws_kms_alias" "docdb" {
  count         = var.enable_rds_mongodb ? 1 : 0
  name          = "alias/${var.project_name}-${var.environment}-docdb"
  target_key_id = aws_kms_key.docdb[0].key_id
}

# Store DocumentDB credentials in AWS Secrets Manager
resource "aws_secretsmanager_secret" "docdb" {
  count                   = var.enable_rds_mongodb ? 1 : 0
  name                    = "${var.project_name}-${var.environment}/docdb/credentials"
  description             = "DocumentDB credentials for ShopNow"
  recovery_window_in_days = 7

  tags = merge(
    local.environment_tag,
    {
      Name = "${var.project_name}-${var.environment}-docdb-credentials"
    }
  )
}

resource "aws_secretsmanager_secret_version" "docdb" {
  count     = var.enable_rds_mongodb ? 1 : 0
  secret_id = aws_secretsmanager_secret.docdb[0].id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.docdb_password[0].result
    host     = aws_docdb_cluster.mongodb[0].endpoint
    port     = 27017
    engine   = "mongodb"
  })
}

# CloudWatch Log Group for DocumentDB
resource "aws_cloudwatch_log_group" "docdb" {
  count             = var.enable_rds_mongodb ? 1 : 0
  name              = "/aws/docdb/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.docdb[0].arn

  tags = merge(
    local.environment_tag,
    {
      Name = "${var.project_name}-${var.environment}-docdb-logs"
    }
  )
}
