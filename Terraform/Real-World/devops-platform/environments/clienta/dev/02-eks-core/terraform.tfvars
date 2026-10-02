aws_region = "us-east-1"

remote_state_bucket = "example-tf-state-123456789012-us-east-1"
network_state_key   = "launchpad/environments/clienta/dev/01-network/terraform.tfstate"

client       = "clienta"
environment  = "dev"
name_prefix  = "clienta-dev"
cluster_name = "clienta-dev-eks"

cluster_version         = "1.35"
endpoint_private_access = true
endpoint_public_access  = true

endpoint_public_access_cidrs = [
  "203.0.113.10/32",
  "203.0.113.20/32"
]
enabled_cluster_log_types = [
  "api",
  "audit",
  "authenticator",
  "controllerManager",
  "scheduler"
]

attach_cni_policy_to_node_role = true

cluster_admin_principal_arns = [
  "arn:aws:iam::123456789012:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_ExampleRole_0000000000000000",
  "arn:aws:iam::123456789012:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_ExampleRole_0000000000000000"
]

platform_admin_principal_arns = []

developer_principal_arns = []

developer_namespaces = [
  "default",
  "clienta-dev-example",
  "app-dev"
]

viewer_principal_arns = []

node_ami_type       = "AL2023_x86_64_STANDARD"
node_capacity_type  = "ON_DEMAND"
node_instance_types = ["t3.large"]

node_desired_size    = 3
node_min_size        = 3
node_max_size        = 5
node_max_unavailable = 1

node_root_volume_size = 50
node_root_volume_type = "gp3"
node_imds_hop_limit   = 1

node_labels = {
  environment = "dev"
  node-type   = "system"
}

node_taints = []

tags = {
  Project   = "devops-launchpad"
  Owner     = "devops"
  Terraform = "true"
}
eks_addons = {
  vpc-cni = {
    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "OVERWRITE"
  }

  kube-proxy = {
    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "OVERWRITE"
  }

  coredns = {
    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "OVERWRITE"
  }

  eks-pod-identity-agent = {
    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "OVERWRITE"
  }
}