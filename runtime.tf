locals {
  name_prefix  = "${var.env}-aster"
  database_url = "postgresql://${var.database_username}:${random_password.database.result}@${aws_db_instance.app.address}:${aws_db_instance.app.port}/${var.database_name}"

  common_environment = [
    { name = "APP_NAME", value = "Aster Studio" },
    { name = "TEMPORAL_NAMESPACE", value = var.temporal_cloud_namespace },
    { name = "TEMPORAL_TLS", value = "true" },
    { name = "TASK_QUEUE", value = "aster-orders" },
    { name = "DEMO_FAIL_FIRST_PAYMENT", value = tostring(var.demo_fail_first_payment) },
  ]

  runtime_secrets = [
    { name = "DATABASE_URL", valueFrom = aws_secretsmanager_secret.database_url.arn },
    { name = "TEMPORAL_ADDRESS", valueFrom = aws_secretsmanager_secret.temporal_address.arn },
    { name = "TEMPORAL_API_KEY", valueFrom = aws_secretsmanager_secret.temporal_api_key.arn },
  ]
}

resource "aws_ecr_repository" "app" {
  name                 = "${local.name_prefix}-app"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration { scan_on_push = true }
}

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name
  policy     = jsonencode({ rules = [{ rulePriority = 1, description = "Keep the latest 30 images", selection = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 30 }, action = { type = "expire" } }] })
}

resource "random_password" "database" {
  length  = 32
  special = false
}

resource "aws_db_subnet_group" "app" {
  name       = "${local.name_prefix}-db"
  subnet_ids = module.vpc.private_subnet_ids
}

resource "aws_security_group" "runtime" {
  name        = "${local.name_prefix}-runtime"
  description = "Aster application and worker tasks"
  vpc_id      = module.vpc.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = var.app_container_port
    to_port         = var.app_container_port
    security_groups = [module.alb.alb_security_group_id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "database" {
  name        = "${local.name_prefix}-database"
  description = "PostgreSQL access from Aster ECS tasks only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 5432
    to_port         = 5432
    security_groups = [aws_security_group.runtime.id]
  }
}

resource "aws_db_instance" "app" {
  identifier                 = "${local.name_prefix}-postgres"
  engine                     = "postgres"
  engine_version             = var.postgres_engine_version
  instance_class             = var.database_instance_class
  allocated_storage          = var.database_allocated_storage
  max_allocated_storage      = var.database_max_allocated_storage
  db_name                    = var.database_name
  username                   = var.database_username
  password                   = random_password.database.result
  port                       = 5432
  db_subnet_group_name       = aws_db_subnet_group.app.name
  vpc_security_group_ids     = [aws_security_group.database.id]
  storage_encrypted          = true
  backup_retention_period    = var.database_backup_retention_days
  deletion_protection        = var.database_deletion_protection
  skip_final_snapshot        = var.database_skip_final_snapshot
  publicly_accessible        = false
  multi_az                   = var.database_multi_az
  auto_minor_version_upgrade = true
  apply_immediately          = false
}

resource "aws_secretsmanager_secret" "database_url" { name = "${local.name_prefix}/database-url" }
resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id     = aws_secretsmanager_secret.database_url.id
  secret_string = local.database_url
}

resource "aws_secretsmanager_secret" "temporal_address" { name = "${local.name_prefix}/temporal-address" }
resource "aws_secretsmanager_secret_version" "temporal_address" {
  secret_id     = aws_secretsmanager_secret.temporal_address.id
  secret_string = var.temporal_cloud_address
}

resource "aws_secretsmanager_secret" "temporal_api_key" { name = "${local.name_prefix}/temporal-api-key" }
resource "aws_secretsmanager_secret_version" "temporal_api_key" {
  secret_id     = aws_secretsmanager_secret.temporal_api_key.id
  secret_string = var.temporal_cloud_api_key
}

resource "aws_ecs_cluster" "app" { name = "${local.name_prefix}-cluster" }

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = var.log_retention
}

data "aws_iam_policy_document" "task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  name               = "${local.name_prefix}-execution"
  assume_role_policy = data.aws_iam_policy_document.task_assume_role.json
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "read_runtime_secrets" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.database_url.arn, aws_secretsmanager_secret.temporal_address.arn, aws_secretsmanager_secret.temporal_api_key.arn]
  }
}

resource "aws_iam_role_policy" "read_runtime_secrets" {
  name   = "read-runtime-secrets"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.read_runtime_secrets.json
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${local.name_prefix}-app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.app_cpu
  memory                   = var.app_memory
  execution_role_arn       = aws_iam_role.execution.arn
  container_definitions = jsonencode([{
    name             = "app", image = var.app_image, essential = true,
    portMappings     = [{ containerPort = var.app_container_port, protocol = "tcp" }],
    environment      = concat(local.common_environment, [{ name = "RECENT_ORDERS_LIMIT", value = "8" }]),
    secrets          = local.runtime_secrets,
    logConfiguration = { logDriver = "awslogs", options = { awslogs-group = aws_cloudwatch_log_group.app.name, awslogs-region = var.region, awslogs-stream-prefix = "app" } }
  }])
}

resource "aws_ecs_task_definition" "worker" {
  family                   = "${local.name_prefix}-worker"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.worker_cpu
  memory                   = var.worker_memory
  execution_role_arn       = aws_iam_role.execution.arn
  container_definitions = jsonencode([{
    name             = "worker", image = var.app_image, essential = true, command = ["python", "-m", "app.worker"],
    environment      = local.common_environment, secrets = local.runtime_secrets,
    logConfiguration = { logDriver = "awslogs", options = { awslogs-group = aws_cloudwatch_log_group.app.name, awslogs-region = var.region, awslogs-stream-prefix = "worker" } }
  }])
}

resource "aws_ecs_service" "app" {
  name            = "${local.name_prefix}-app"
  cluster         = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.app_desired_count
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = module.vpc.private_subnet_ids
    security_groups  = [aws_security_group.runtime.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = module.alb.target_group_arn
    container_name   = "app"
    container_port   = var.app_container_port
  }
  depends_on = [aws_iam_role_policy_attachment.execution]
}

resource "aws_ecs_service" "worker" {
  name            = "${local.name_prefix}-worker"
  cluster         = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = var.worker_desired_count
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = module.vpc.private_subnet_ids
    security_groups  = [aws_security_group.runtime.id]
    assign_public_ip = false
  }
  depends_on = [aws_iam_role_policy_attachment.execution]
}
