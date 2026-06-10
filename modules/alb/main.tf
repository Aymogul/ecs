# Create security group for ALB
resource "aws_security_group" "alb" {
  name        = "${var.env}-alb-sg"
  description = "Security Group for ALB"

  vpc_id = var.vpc_id

  ingress {
    from_port   = var.listener_port
    to_port     = var.listener_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.env}-alb-sg"
    Environment = var.env
  }
}

# Create ALB listener and target group
resource "aws_lb" "this" {
  name               = "${var.env}-alb"
  internal           = false
  load_balancer_type = "application"

  subnets = var.public_subnet_ids

  security_groups = [aws_security_group.alb.id]

  tags = {
    Name        = "${var.env}-alb"
    Environment = var.env
  }
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.listener_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.this.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "this" {
  name        = "${var.env}-tg"
  port        = var.target_port
  protocol    = "HTTP"
  target_type = "ip"

  vpc_id = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 10
    path                = var.health_check_path
    matcher             = "200-399"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.env}-tg"
    Environment = var.env
  }
}
