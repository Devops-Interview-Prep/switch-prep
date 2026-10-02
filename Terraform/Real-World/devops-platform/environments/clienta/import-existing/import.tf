# ──────────────────────────────────────────────────────────────
# Import blocks for existing CLIENTA dev infrastructure
# Run: terraform init && terraform plan
# ──────────────────────────────────────────────────────────────

import {
  to = aws_vpc.main
  id = "vpc-a499562f85a2b0414"
}

import {
  to = aws_subnet.public_1
  id = "subnet-2f6e04c60ae5242b7"
}
import {
  to = aws_subnet.public_2
  id = "subnet-aa5b74cfb8cb99b59"
}
import {
  to = aws_subnet.private_app_1
  id = "subnet-b2eefd103c383fd02"
}
import {
  to = aws_subnet.private_app_2
  id = "subnet-4b838f0ad5c9f6306"
}
import {
  to = aws_subnet.private_app_3
  id = "subnet-a0b0a172cc63c8812"
}
import {
  to = aws_subnet.private_db_1
  id = "subnet-40c4d1f4f7c952216"
}
import {
  to = aws_subnet.private_db_2
  id = "subnet-b8ff50b6e415172b8"
}
import {
  to = aws_subnet.private_db_3
  id = "subnet-139451ad7d29ffa1a"
}

import {
  to = aws_internet_gateway.main
  id = "igw-c6e2f18743820a06e"
}

import {
  to = aws_eip.nat_1
  id = "eipalloc-1d20a2b9419322858"
}
import {
  to = aws_eip.nat_2
  id = "eipalloc-426be0d83347bba03"
}

import {
  to = aws_nat_gateway.nat_1
  id = "nat-300a0e17f2f15e19e"
}
import {
  to = aws_nat_gateway.nat_2
  id = "nat-61a20f6e429c5c73b"
}

import {
  to = aws_route_table.public
  id = "rtb-872cd7919e9c76151"
}
import {
  to = aws_route_table.private_app_1
  id = "rtb-d6970a7cd2a2936a0"
}
import {
  to = aws_route_table.private_app_2
  id = "rtb-52d4745f0c53dff0c"
}
import {
  to = aws_route_table.private_app_3
  id = "rtb-74d3db1ada87031e9"
}
import {
  to = aws_route_table.private_db
  id = "rtb-c8939be670a4e63c5"
}

import {
  to = aws_route_table_association.public_1
  id = "rtbassoc-4946c87395fcc1fbf"
}
import {
  to = aws_route_table_association.public_2
  id = "rtbassoc-a5c9e2e3ea73807a3"
}
import {
  to = aws_route_table_association.private_app_1
  id = "rtbassoc-6d3eb74208c2077f5"
}
import {
  to = aws_route_table_association.private_app_2
  id = "rtbassoc-9195738202e524646"
}
import {
  to = aws_route_table_association.private_app_3
  id = "rtbassoc-f79b8be6e14c2da1d"
}
import {
  to = aws_route_table_association.private_db_1
  id = "rtbassoc-afee8b7e004d59cd2"
}
import {
  to = aws_route_table_association.private_db_2
  id = "rtbassoc-643410824aefd6a2e"
}
import {
  to = aws_route_table_association.private_db_3
  id = "rtbassoc-ee1cd9cb0302b9f8c"
}

import {
  to = aws_security_group.cluster
  id = "sg-91200a980a531440f"
}
import {
  to = aws_security_group.node
  id = "sg-251e056ed70475834"
}
import {
  to = aws_security_group.database
  id = "sg-2c8f376690134200a"
}

import {
  to = aws_iam_openid_connect_provider.main
  id = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED0C1234567890ABCDEF123456"
}

import {
  to = aws_iam_role.cluster
  id = "clienta-deployment-eks-cluster-role"
}
import {
  to = aws_iam_role.node
  id = "clienta-deployment-eks-node-role"
}
import {
  to = aws_iam_role.karpenter
  id = "clienta-deployment-eks-karpenter-controller-role"
}
import {
  to = aws_iam_role.alb_controller
  id = "clienta-deployment-eks-aws-load-balancer-controller-role"
}
import {
  to = aws_iam_role.ebs_csi
  id = "clienta-deployment-eks-ebs-csi-role"
}

import {
  to = aws_iam_role_policy_attachment.cluster_eks
  id = "clienta-deployment-eks-cluster-role/arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
import {
  to = aws_iam_role_policy_attachment.cluster_vpc_controller
  id = "clienta-deployment-eks-cluster-role/arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}
import {
  to = aws_iam_role_policy_attachment.node_worker
  id = "clienta-deployment-eks-node-role/arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
import {
  to = aws_iam_role_policy_attachment.node_cni
  id = "clienta-deployment-eks-node-role/arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
import {
  to = aws_iam_role_policy_attachment.node_ecr
  id = "clienta-deployment-eks-node-role/arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
import {
  to = aws_iam_role_policy_attachment.node_ebs
  id = "clienta-deployment-eks-node-role/arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}
import {
  to = aws_iam_role_policy_attachment.karpenter_controller
  id = "clienta-deployment-eks-karpenter-controller-role/arn:aws:iam::123456789012:policy/clienta-deployment-eks-karpenter-controller-policy"
}
import {
  to = aws_iam_role_policy_attachment.alb_controller
  id = "clienta-deployment-eks-aws-load-balancer-controller-role/arn:aws:iam::123456789012:policy/clienta-deployment-eks-aws-load-balancer-controller-policy"
}
import {
  to = aws_iam_role_policy_attachment.ebs_csi
  id = "clienta-deployment-eks-ebs-csi-role/arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

import {
  to = aws_eks_cluster.main
  id = "clienta-deployment-eks"
}

import {
  to = aws_eks_node_group.main
  id = "clienta-deployment-eks:clienta-deployment-eks-ng-01"
}

import {
  to = aws_eks_addon.vpc_cni
  id = "clienta-deployment-eks:vpc-cni"
}
import {
  to = aws_eks_addon.kube_proxy
  id = "clienta-deployment-eks:kube-proxy"
}
import {
  to = aws_eks_addon.coredns
  id = "clienta-deployment-eks:coredns"
}
import {
  to = aws_eks_addon.ebs_csi
  id = "clienta-deployment-eks:aws-ebs-csi-driver"
}
import {
  to = aws_eks_addon.efs_csi
  id = "clienta-deployment-eks:aws-efs-csi-driver"
}

import {
  to = aws_sqs_queue.karpenter_interruption
  id = "https://sqs.us-east-1.amazonaws.com/123456789012/clienta-deployment-eks-karpenter-interruption-queue"
}
import {
  to = aws_sqs_queue_policy.karpenter_interruption
  id = "https://sqs.us-east-1.amazonaws.com/123456789012/clienta-deployment-eks-karpenter-interruption-queue"
}

import {
  to = aws_cloudwatch_event_rule.karpenter_spot_interruption
  id = "clienta-deployment-eks-karpenter-spot-interruption"
}
import {
  to = aws_cloudwatch_event_rule.karpenter_rebalance
  id = "clienta-deployment-eks-karpenter-rebalance"
}
import {
  to = aws_cloudwatch_event_rule.karpenter_instance_state_change
  id = "clienta-deployment-eks-karpenter-instance-state-change"
}
import {
  to = aws_cloudwatch_event_rule.karpenter_scheduled_change
  id = "clienta-deployment-eks-karpenter-scheduled-change"
}

import {
  to = aws_cloudwatch_event_target.karpenter_spot_interruption
  id = "clienta-deployment-eks-karpenter-spot-interruption/KarpenterInterruptionQueue"
}
import {
  to = aws_cloudwatch_event_target.karpenter_rebalance
  id = "clienta-deployment-eks-karpenter-rebalance/KarpenterInterruptionQueue"
}
import {
  to = aws_cloudwatch_event_target.karpenter_instance_state_change
  id = "clienta-deployment-eks-karpenter-instance-state-change/KarpenterInterruptionQueue"
}
import {
  to = aws_cloudwatch_event_target.karpenter_scheduled_change
  id = "clienta-deployment-eks-karpenter-scheduled-change/KarpenterInterruptionQueue"
}
