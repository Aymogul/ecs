locals {
  name          = "${var.env}-temporal"
  server_port   = 7233
  ui_port       = 8233
  database_name = "temporal"
}

resource "aws_ecs_cluster" "this" {
  name = "${local.name}-cluster"

  tags = {
    Environment = var.env
    Service     = "temporal"
  }
}

resource "aws_iam_role" "task_execution" {
  name = "${local.name}-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_security_group" "ui_alb" {
  name        = "${local.name}-ui-alb-sg"
  description = "Security group for Temporal UI ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_ui_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name}-ui-alb-sg"
    Environment = var.env
    Service     = "temporal"
  }
}

resource "aws_security_group" "task" {
  name        = "${local.name}-task-sg"
  description = "Security group for Temporal ECS task"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = local.ui_port
    to_port         = local.ui_port
    protocol        = "tcp"
    security_groups = [aws_security_group.ui_alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name}-task-sg"
    Environment = var.env
    Service     = "temporal"
  }
}

resource "aws_security_group" "db" {
  name        = "${local.name}-db-sg"
  description = "Security group for Temporal PostgreSQL"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.task.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name}-db-sg"
    Environment = var.env
    Service     = "temporal"
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.name}-db-subnets"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${local.name}-db-subnets"
    Environment = var.env
    Service     = "temporal"
  }
}

resource "aws_db_instance" "this" {
  identifier             = "${local.name}-postgres"
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = var.db_instance_class
  db_name                = local.database_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  deletion_protection    = false

  tags = {
    Name        = "${local.name}-postgres"
    Environment = var.env
    Service     = "temporal"
  }
}

resource "aws_lb" "ui" {
  name               = "${local.name}-ui"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ui_alb.id]
  subnets            = var.public_subnet_ids

  tags = {
    Name        = "${local.name}-ui"
    Environment = var.env
    Service     = "temporal"
  }
}

resource "aws_lb_target_group" "ui" {
  name        = "${local.name}-ui"
  port        = local.ui_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200-399"
    path                = "/"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${local.name}-ui"
    Environment = var.env
    Service     = "temporal"
  }
}

resource "aws_lb_listener" "ui" {
  load_balancer_arn = aws_lb.ui.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ui.arn
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${local.name}"
  retention_in_days = var.log_retention

  tags = {
    Environment = var.env
    Service     = "temporal"
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${local.name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)
  execution_role_arn       = aws_iam_role.task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "temporal"
      image     = var.temporal_image
      essential = true
      portMappings = [
        {
          containerPort = local.server_port
          hostPort      = local.server_port
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "DB"
          value = "postgres12"
        },
        {
          name  = "DB_PORT"
          value = "5432"
        },
        {
          name  = "POSTGRES_SEEDS"
          value = aws_db_instance.this.address
        },
        {
          name  = "POSTGRES_USER"
          value = var.db_username
        },
        {
          name  = "POSTGRES_PWD"
          value = var.db_password
        },
        {
          name  = "DYNAMIC_CONFIG_FILE_PATH"
          value = "config/dynamicconfig/development-sql.yaml"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "temporal"
        }
      }
    },
    {
      name      = "temporal-ui"
      image     = var.temporal_ui_image
      essential = true
      portMappings = [
        {
          containerPort = local.ui_port
          hostPort      = local.ui_port
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "TEMPORAL_ADDRESS"
          value = "127.0.0.1:${local.server_port}"
        },
        {
          name  = "TEMPORAL_CORS_ORIGINS"
          value = "http://${aws_lb.ui.dns_name}"
        }
      ]
      dependsOn = [
        {
          containerName = "temporal"
          condition     = "START"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "temporal-ui"
        }
      }
    }
  ])

  tags = {
    Environment = var.env
    Service     = "temporal"
  }
}

resource "aws_ecs_service" "this" {
  name            = "${local.name}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.task.id]
    subnets          = var.private_subnet_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ui.arn
    container_name   = "temporal-ui"
    container_port   = local.ui_port
  }

  tags = {
    Environment = var.env
    Service     = "temporal"
  }

  depends_on = [
    aws_db_instance.this,
    aws_iam_role_policy_attachment.task_execution,
    aws_lb_listener.ui
  ]
}
