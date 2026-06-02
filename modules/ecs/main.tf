# Configure the AWS Provider
provider "aws" {
  region = var.region
}

# Create ECS cluster
resource "aws_ecs_cluster" "this" {
  name = "${var.env}-ecs-cluster"
}

# Create task definition
resource "aws_ecs_task_definition" "this" {
  family                = "${var.env}-task-definition"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                  = var.memory
  network_mode            = "awsvpc"

  container_definitions = jsonencode([
    {
      name               = "${var.env}-container"
      image              = var.image
      essential          = true
      portMappings       = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
    }
  ])
}

# Create ECS service
resource "aws_ecs_service" "this" {
  name            = "${var.env}-ecs-service"
  cluster         = aws_ecs_cluster.this.name
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count

  launch_type = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.ecs.id]
    subnets          = module.vpc.outputs.private_subnet_ids
  }
}

# Create CloudWatch logs
resource "aws_cloudwatch_log_group" "this" {
  name              = "${var.env}-ecs-log-group"
  retention_in_days = var.log_retention

  tags = {
    Environment = var.env
  }
}

# Create auto scaling group
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${var.env}-ecs-service"
  role_arn           = aws_iam_role.ecs.arn
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.this]
}

resource "aws_appautoscaling_policy" "ecs" {
  name               = "${var.env}-ecs-policy"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = "ecs:service:DesiredCount"

  step_adjustment {
    scaling_adjustment     = var.scaling_adjustment
    metric_aggregation_type = "MAX"
  }
}
