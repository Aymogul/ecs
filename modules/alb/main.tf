# Configure the AWS Provider
provider "aws" {
  region = var.region
}

# Create security group for ALB
resource "aws_security_group" "alb" {
  name        = "${var.env}-alb-sg"
  description = "Security Group for ALB"

  vpc_id = module.vpc.outputs.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create ALB listener and target group
resource "aws_lb" "this" {
  name               = "${var.env}-alb"
  internal           = false
  load_balancer_type = "application"

  subnets = module.vpc.outputs.public_subnet_ids

  security_groups = [aws_security_group.alb.id]
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn = aws_acm_certificate.this.arn

  timeouts {
    create = "5m"
  }

  depends_on = [aws_route53_record.validation]
}

resource "aws_acm_certificate" "this" {
  domain_name       = "*.${var.env}.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  for_each = aws_acm_certificate_validation.this.validation_record

  zone_id = var.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = "300"
  records = [each.value.alias]
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = "443"
  protocol          = "HTTPS"

  certificate_arn = aws_acm_certificate_validation.this.certificate_arn

  default_action {
    target_group_arn = aws_lb_target_group.this.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "this" {
  name     = "${var.env}-tg"
  port     = "80"
  protocol = "HTTP"

  vpc_id = module.vpc.outputs.vpc_id

  health_check {
    enabled         = true
    healthy_threshold = 2
    interval        = 10
    path            = "/"
    matcher         = "200-299"
    timeout        = 5
    unhealthy_threshold = 2
  }
}
