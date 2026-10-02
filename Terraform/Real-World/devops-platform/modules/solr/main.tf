terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}

# ── AMI — Amazon Linux 2023 ──────────────────────────────────────────────────
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "this" {
  id = var.vpc_id
}

# ── Security Group ───────────────────────────────────────────────────────────
resource "aws_security_group" "solr" {
  name_prefix = "${var.name}-solr-"
  description = "Solr node - ${var.name}"
  vpc_id      = var.vpc_id

  # Solr HTTP API — from VPC CIDR and any explicit ranges
  ingress {
    description = "Solr HTTP"
    from_port   = var.solr_port
    to_port     = var.solr_port
    protocol    = "tcp"
    cidr_blocks = concat([data.aws_vpc.this.cidr_block], var.allow_cidr_blocks)
  }

  # ZooKeeper embedded mode (Solr 7+)
  ingress {
    description = "ZooKeeper"
    from_port   = 9983
    to_port     = 9983
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.this.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-solr-sg" })

  lifecycle { create_before_destroy = true }
}

# ── IAM — SSM access ─────────────────────────────────────────────────────────
resource "aws_iam_role" "solr" {
  name = "${var.name}-solr-role"

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

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.solr.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "s3_read" {
  role       = aws_iam_role.solr.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "solr" {
  name = "${var.name}-solr-profile"
  role = aws_iam_role.solr.name
}

# ── EC2 Instance ─────────────────────────────────────────────────────────────
resource "aws_instance" "solr" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  iam_instance_profile   = aws_iam_instance_profile.solr.name
  vpc_security_group_ids = [aws_security_group.solr.id]

  root_block_device {
    volume_size           = var.data_volume_gb
    volume_type           = "gp3"
    throughput            = 125
    delete_on_termination = true
    encrypted             = true
  }

  user_data = base64encode(templatefile("${path.module}/templates/install-solr.sh.tpl", {
    solr_version       = var.solr_version
    solr_port          = var.solr_port
    solr_auth_user     = var.solr_auth_user
    solr_auth_password = var.solr_auth_password
    heap_size_gb       = var.heap_size_gb
    collections        = var.collections
    collection_configs = var.collection_configs
  }))

  tags = merge(var.tags, {
    Name    = "${var.name}-solr"
    Role    = "solr"
    Product = split("-", var.name)[2]
  })

  lifecycle {
    ignore_changes = [ami]
  }
}

# ── CloudWatch alarm — instance health ───────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "solr_status" {
  alarm_name          = "${var.name}-solr-status"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "Solr EC2 status check"

  dimensions = { InstanceId = aws_instance.solr.id }
  tags       = var.tags
}
