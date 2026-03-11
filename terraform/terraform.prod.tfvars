aws_region     = "us-east-1"
project_name   = "ecs-fullstack"
vpc_cidr       = "10.0.0.0/16"
domain_name    = "example.com"

github_org  = "my-org"
github_repo = "aws-ecs-fullstack"

create_github_oidc_provider = false

container_insights_enabled = true

first_superuser          = "admin@yourdomain.com"
first_superuser_password = "REPLACE_WITH_STRONG_PASSWORD"
