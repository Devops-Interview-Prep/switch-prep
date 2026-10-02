terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}

data "aws_vpc" "this" {
  id = var.vpc_id
}

# ── Security Group ────────────────────────────────────────────────────────────
resource "aws_security_group" "ra" {
  name_prefix = "${var.name}-ra-"
  description = "RA roster-app EC2 - ${var.name}"
  vpc_id      = var.vpc_id

  # Application port
  ingress {
    description = "RA app"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = concat([data.aws_vpc.this.cidr_block], var.allow_cidr_blocks)
  }

  # Control plane port
  ingress {
    description = "RA control plane"
    from_port   = var.control_plane_port
    to_port     = var.control_plane_port
    protocol    = "tcp"
    cidr_blocks = concat([data.aws_vpc.this.cidr_block], var.allow_cidr_blocks)
  }

  # Orchestrator port
  ingress {
    description = "RA orchestrator"
    from_port   = var.orchestrator_port
    to_port     = var.orchestrator_port
    protocol    = "tcp"
    cidr_blocks = concat([data.aws_vpc.this.cidr_block], var.allow_cidr_blocks)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-ra-sg" })
  lifecycle { create_before_destroy = true }
}

# ── IAM Role ──────────────────────────────────────────────────────────────────
resource "aws_iam_role" "ra" {
  name = "${var.name}-ra-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "ra_ecr_secrets" {
  name = "${var.name}-ra-policy"
  role = aws_iam_role.ra.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAuth"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
        ]
        Resource = "*"
      },
      {
        Sid      = "RdsCredsSecret"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        Resource = "arn:aws:secretsmanager:*:*:secret:${var.rds_secret_name}*"
      },
      {
        Sid      = "EnvSecret"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        Resource = "arn:aws:secretsmanager:*:*:secret:${var.env_secret_name}*"
      },
      {
        Sid    = "S3DeployScripts"
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket}",
          "arn:aws:s3:::${var.s3_bucket}/${var.s3_deploy_prefix}/*",
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ra.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ra" {
  name = "${var.name}-ra-profile"
  role = aws_iam_role.ra.name
  tags = var.tags
}

# ── EC2 Instances ─────────────────────────────────────────────────────────────
resource "aws_instance" "ra" {
  count                  = var.instance_count
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  iam_instance_profile   = aws_iam_instance_profile.ra.name
  vpc_security_group_ids = [aws_security_group.ra.id]

  root_block_device {
    volume_size           = var.root_volume_gb
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = base64encode(templatefile("${path.module}/templates/bootstrap.sh.tpl", {
    ecr_registry     = var.ecr_registry
    ecr_region       = var.ecr_region
    rds_secret_name  = var.rds_secret_name
    s3_bucket        = var.s3_bucket
    s3_deploy_prefix = var.s3_deploy_prefix
    env_secret_name  = var.env_secret_name
  }))

  tags = merge(var.tags, {
    Name    = var.instance_count > 1 ? "${var.name}-ra-${count.index + 1}" : "${var.name}-ra"
    Role    = "ra"
    Service = "roster-app"
  })

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

# ── CloudWatch alarms — one per instance ─────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "ra_status" {
  count               = var.instance_count
  alarm_name          = var.instance_count > 1 ? "${var.name}-ra-status-${count.index + 1}" : "${var.name}-ra-status"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "RA EC2 status check — ${var.name} instance ${count.index + 1}"

  dimensions = { InstanceId = aws_instance.ra[count.index].id }
  tags       = var.tags
}
