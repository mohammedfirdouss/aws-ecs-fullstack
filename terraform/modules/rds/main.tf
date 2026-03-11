resource "random_password" "db" {
  length  = 32
  special = false
}


resource "aws_secretsmanager_secret" "db" {
  name                    = "${var.project_name}/db-credentials"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.project_name}-db-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  # Keys match the env var names the fastapi/full-stack-fastapi-template expects.
  # ECS task definitions inject each key individually via ::key:: valueFrom notation.
  secret_string = jsonencode({
    POSTGRES_SERVER   = aws_db_instance.this.address
    POSTGRES_PORT     = "5432"
    POSTGRES_DB       = var.db_name
    POSTGRES_USER     = var.db_username
    POSTGRES_PASSWORD = random_password.db.result
  })

  depends_on = [aws_db_instance.this]
}


resource "aws_db_subnet_group" "this" {
  name        = "${var.project_name}-db-subnet-group"
  subnet_ids  = var.isolated_subnet_ids
  description = "Isolated subnet group for ${var.project_name} RDS."

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}


resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds"
  description = "Allow PostgreSQL from ECS backend only."
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_sg_ids
    content {
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      source_security_group_id = ingress.value
      description              = "PostgreSQL from ${ingress.value}"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

resource "aws_db_instance" "this" {
  identifier        = "${var.project_name}-postgres"
  engine            = "postgres"
  engine_version    = "16"
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az                    = var.multi_az
  publicly_accessible         = false
  backup_retention_period     = 7
  deletion_protection         = var.multi_az
  skip_final_snapshot         = !var.multi_az
  final_snapshot_identifier   = var.multi_az ? "${var.project_name}-postgres-final" : null
  auto_minor_version_upgrade  = true
  apply_immediately           = !var.multi_az

  tags = {
    Name = "${var.project_name}-postgres"
  }

  lifecycle {
    ignore_changes = [password]
  }
}
