resource "aws_launch_template" "this" {
  name_prefix            = "${var.node_group_name}-"
  update_default_version = true

  vpc_security_group_ids = var.node_security_group_ids

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = var.imds_hop_limit
    instance_metadata_tags      = "disabled"
  }

  block_device_mappings {
    device_name = var.root_device_name

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(var.tags, {
      Name      = var.node_group_name
      Role      = "eks-managed-node"
      ManagedBy = "devops-launchpad"
    })
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(var.tags, {
      Name      = "${var.node_group_name}-root-volume"
      Role      = "eks-managed-node-volume"
      ManagedBy = "devops-launchpad"
    })
  }

  tags = merge(var.tags, {
    Name      = "${var.node_group_name}-lt"
    Role      = "eks-node-launch-template"
    ManagedBy = "devops-launchpad"
  })
}

resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  ami_type       = var.ami_type
  capacity_type  = var.capacity_type
  instance_types = var.instance_types

  labels = var.labels

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  update_config {
    max_unavailable = var.max_unavailable
  }

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  dynamic "taint" {
    for_each = var.taints

    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = merge(var.tags, {
    Name      = var.node_group_name
    Role      = "eks-managed-node-group"
    ManagedBy = "devops-launchpad"
  })
}