resource "aws_security_group" "eks_cluster" {
  name        = "${var.name_prefix}-eks-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-eks-cluster-sg"
    Role = "eks-cluster"
  })
}

resource "aws_security_group" "eks_nodes" {
  name        = "${var.name_prefix}-eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    var.karpenter_discovery_tag_value != null && var.karpenter_discovery_tag_value != "" ? {
      "karpenter.sh/discovery" = var.karpenter_discovery_tag_value
    } : {},
    {
      Name = "${var.name_prefix}-eks-nodes-sg"
      Role = "eks-nodes"
    }
  )
}

resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-app-sg"
  description = "Security group for application workloads"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-app-sg"
    Role = "app"
  })
}

resource "aws_security_group" "db" {
  name        = "${var.name_prefix}-db-sg"
  description = "Security group for database resources"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-sg"
    Role = "database"
  })
}

resource "aws_security_group_rule" "eks_cluster_ingress_nodes_https" {
  description              = "Allow worker nodes to reach EKS control plane HTTPS"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_security_group_rule" "eks_nodes_ingress_self" {
  description       = "Allow all node-to-node communication inside the EKS node security group"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks_nodes.id
  self              = true
}
resource "aws_security_group_rule" "eks_nodes_egress_self" {
  description       = "Allow all node-to-node outbound communication inside the EKS node security group"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks_nodes.id
  self              = true
}

resource "aws_security_group_rule" "eks_nodes_ingress_cluster" {
  description              = "Allow EKS control plane to communicate with nodes"
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
}

resource "aws_security_group_rule" "eks_nodes_egress_all" {
  description       = "Allow worker node outbound traffic"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks_nodes.id
  cidr_blocks       = var.egress_cidr_blocks
}

resource "aws_security_group_rule" "eks_cluster_egress_all" {
  description       = "Allow EKS control plane outbound traffic"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks_cluster.id
  cidr_blocks       = var.egress_cidr_blocks
}

resource "aws_security_group_rule" "app_egress_all" {
  description       = "Allow application outbound traffic"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.app.id
  cidr_blocks       = var.egress_cidr_blocks
}

resource "aws_security_group_rule" "db_ingress_mysql_from_app" {
  count = var.enable_mysql_rule ? 1 : 0

  description              = "Allow MySQL from application security group"
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = aws_security_group.app.id
}

resource "aws_security_group_rule" "db_ingress_postgresql_from_app" {
  count = var.enable_postgresql_rule ? 1 : 0

  description              = "Allow PostgreSQL from application security group"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = aws_security_group.app.id
}

resource "aws_security_group_rule" "db_egress_all" {
  description       = "Allow database outbound traffic"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.db.id
  cidr_blocks       = var.egress_cidr_blocks
}
