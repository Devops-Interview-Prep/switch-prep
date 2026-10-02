terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}

# ── Security Group ────────────────────────────────────────────────────────────
resource "aws_security_group" "alb" {
  name_prefix = "${var.name}-alb-"
  description = "ALB - ${var.name}"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.listener_ports
    content {
      description = "ALB listener port ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-alb-sg" })
  lifecycle { create_before_destroy = true }
}

# ── Application Load Balancer ─────────────────────────────────────────────────
resource "aws_lb" "this" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = var.deletion_protection

  tags = merge(var.tags, { Name = var.name })
}

# ── Target Groups ─────────────────────────────────────────────────────────────
resource "aws_lb_target_group" "app" {
  name        = "${var.name}-app-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = var.app_health_path
    matcher             = "200-399"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(var.tags, { Name = "${var.name}-app-tg" })
}

resource "aws_lb_target_group" "control_plane" {
  name        = "${var.name}-cp-tg"
  port        = var.control_plane_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = var.api_health_path
    matcher             = "200-399"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(var.tags, { Name = "${var.name}-cp-tg" })
}

resource "aws_lb_target_group" "orchestrator" {
  name        = "${var.name}-orch-tg"
  port        = var.orchestrator_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = var.api_health_path
    matcher             = "200-399"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(var.tags, { Name = "${var.name}-orch-tg" })
}

# ── Listener — app port (main entry) ─────────────────────────────────────────
resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.app_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  tags = var.tags
}

# ── Listener — control plane port ────────────────────────────────────────────
resource "aws_lb_listener" "control_plane" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.control_plane_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.control_plane.arn
  }

  tags = var.tags
}

# ── Listener — orchestrator port ─────────────────────────────────────────────
resource "aws_lb_listener" "orchestrator" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.orchestrator_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.orchestrator.arn
  }

  tags = var.tags
}
