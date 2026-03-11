data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  is_prod = terraform.workspace == "prod"

  # Constructed ARN references — avoids circular dependency (iam→rds→ecs→iam).
  # Wildcard form used in IAM policies; base form used in ECS valueFrom.
  db_secret_name        = "${var.project_name}/db-credentials"
  db_secret_arn_base    = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${local.db_secret_name}"
  db_secret_arn_pattern = "${local.db_secret_arn_base}*"  # for IAM resource scoping

  # Database sizing
  db_instance_class = local.is_prod ? "db.t3.medium" : "db.t3.micro"
  db_multi_az       = local.is_prod

  # ECS task sizing
  backend_cpu    = local.is_prod ? 1024 : 512
  backend_memory = local.is_prod ? 2048 : 1024
  frontend_cpu   = local.is_prod ? 512 : 256
  frontend_memory = local.is_prod ? 1024 : 512

  # Auto-scaling bounds
  backend_min_capacity  = local.is_prod ? 2 : 1
  backend_max_capacity  = local.is_prod ? 10 : 3
  frontend_min_capacity = local.is_prod ? 2 : 1
  frontend_max_capacity = local.is_prod ? 6 : 2
}

module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
}


module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
}


module "iam" {
  source = "./modules/iam"

  project_name                = var.project_name
  secret_arns                 = [local.db_secret_arn_pattern, local.app_secret_arn_pattern]
  create_github_oidc_provider = var.create_github_oidc_provider
  github_org                  = var.github_org
  github_repo                 = var.github_repo
}


module "rds" {
  source = "./modules/rds"

  project_name        = var.project_name
  isolated_subnet_ids = module.networking.isolated_subnet_ids
  allowed_sg_ids      = []   # ingress rule added below to break ecs→rds→ecs cycle
  instance_class      = local.db_instance_class
  multi_az            = local.db_multi_az
  vpc_id              = module.networking.vpc_id
}

# Add ECS backend → RDS ingress rule at root level (breaks the circular
# dependency that would otherwise form: ecs→rds→ecs).
resource "aws_security_group_rule" "backend_to_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = module.ecs.backend_sg_id
  security_group_id        = module.rds.rds_sg_id
  description              = "PostgreSQL from ECS backend"
}

# Stores SECRET_KEY (randomly generated) and initial superuser credentials.
# Populate or rotate via Secrets Manager console / CLI after first apply.

resource "random_password" "secret_key" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "app" {
  name                    = "${var.project_name}/app-config"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.project_name}-app-config"
  }
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id

  secret_string = jsonencode({
    SECRET_KEY               = random_password.secret_key.result
    FIRST_SUPERUSER          = var.first_superuser
    FIRST_SUPERUSER_PASSWORD = var.first_superuser_password
  })
}

locals {
  app_secret_arn_base    = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/app-config"
  app_secret_arn_pattern = "${local.app_secret_arn_base}*"
}


module "alb" {
  source = "./modules/alb"

  project_name      = var.project_name
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  domain_name       = var.domain_name
}


module "ecs" {
  source = "./modules/ecs"

  project_name           = var.project_name
  vpc_id                 = module.networking.vpc_id
  private_subnet_ids     = module.networking.private_subnet_ids
  alb_sg_id              = module.alb.alb_sg_id
  backend_tg_arn         = module.alb.backend_tg_arn
  frontend_tg_arn        = module.alb.frontend_tg_arn
  task_execution_role_arn = module.iam.task_execution_role_arn
  task_role_arn          = module.iam.task_role_arn
  # Use the constructed ARN pattern to avoid a circular dependency with RDS.
  # Secrets Manager allows referencing secrets by base ARN (without the
  # AWS-appended 6-char random suffix) in ECS task definition valueFrom fields.
  db_secret_arn          = local.db_secret_arn_base
  app_secret_arn         = local.app_secret_arn_base
  domain_name            = var.domain_name
  backend_image          = var.backend_image
  frontend_image         = var.frontend_image
  backend_cpu            = local.backend_cpu
  backend_memory         = local.backend_memory
  frontend_cpu           = local.frontend_cpu
  frontend_memory        = local.frontend_memory
  backend_min_capacity   = local.backend_min_capacity
  backend_max_capacity   = local.backend_max_capacity
  frontend_min_capacity  = local.frontend_min_capacity
  frontend_max_capacity  = local.frontend_max_capacity
  container_insights     = var.container_insights_enabled
  aws_region             = var.aws_region
}


module "observability" {
  source = "./modules/observability"

  project_name              = var.project_name
  backend_service_name      = module.ecs.backend_service_name
  frontend_service_name     = module.ecs.frontend_service_name
  cluster_name              = module.ecs.cluster_name
  backend_tg_arn_suffix     = module.alb.backend_tg_arn_suffix
  frontend_tg_arn_suffix    = module.alb.frontend_tg_arn_suffix
  alb_arn_suffix            = module.alb.alb_arn_suffix
  db_instance_id            = module.rds.db_instance_id
}
