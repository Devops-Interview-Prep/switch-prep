# ── Identity ─────────────────────────────────────────────────────────────────
variable "name" {
  description = "EMR cluster name."
  type        = string
}

# ── Release & Applications ────────────────────────────────────────────────────
variable "release_label" {
  description = "EMR release label (e.g. emr-7.12.0)."
  type        = string
  default     = "emr-7.12.0"
}

variable "applications" {
  description = "List of EMR applications to install."
  type        = list(string)
  default     = ["Hadoop", "Hive", "JupyterEnterpriseGateway", "Spark"]
}

# ── IAM ───────────────────────────────────────────────────────────────────────
variable "service_role" {
  description = "IAM role ARN or name for the EMR service."
  type        = string
  default     = "EMR_DefaultRole"
}

variable "instance_profile" {
  description = "IAM instance profile name for EMR EC2 nodes."
  type        = string
  default     = "EMR_EC2_DefaultRole"
}

# ── Networking ────────────────────────────────────────────────────────────────
variable "subnet_id" {
  description = "Subnet ID for EMR cluster nodes."
  type        = string
}

variable "ec2_key_name" {
  description = "EC2 key pair name for SSH access to nodes."
  type        = string
  default     = "example-app-key"
}

# ── Security ──────────────────────────────────────────────────────────────────
variable "security_configuration" {
  description = "Name of the EMR security configuration to use."
  type        = string
  default     = "example-EMR-Security-Config"
}

# ── Master Node ───────────────────────────────────────────────────────────────
variable "master_instance_type" {
  description = "EC2 instance type for the master node."
  type        = string
  default     = "r6a.xlarge"
}

variable "master_ebs_size" {
  description = "EBS volume size in GB for the master node."
  type        = number
  default     = 70
}

# ── Core Nodes ────────────────────────────────────────────────────────────────
variable "core_instance_type" {
  description = "EC2 instance type for core nodes."
  type        = string
  default     = "r6a.xlarge"
}

variable "core_instance_count" {
  description = "Initial core node count. Lifecycle-ignored so EMR scaling does not get overridden."
  type        = number
  default     = 1
}

variable "core_ebs_size" {
  description = "EBS volume size in GB for core nodes."
  type        = number
  default     = 55
}

# ── EBS Root ──────────────────────────────────────────────────────────────────
variable "ebs_root_volume_size" {
  description = "Root EBS volume size in GB for all nodes."
  type        = number
  default     = 55
}

# ── Cluster Behaviour ─────────────────────────────────────────────────────────
variable "scale_down_behavior" {
  description = "Node decommission behavior: TERMINATE_AT_TASK_COMPLETION or TERMINATE_AT_INSTANCE_HOUR."
  type        = string
  default     = "TERMINATE_AT_TASK_COMPLETION"
}

variable "step_concurrency_level" {
  description = "Number of steps that can run concurrently."
  type        = number
  default     = 10
}

variable "termination_protection" {
  description = "Enable termination protection on the cluster."
  type        = bool
  default     = false
}

variable "log_uri" {
  description = "S3 URI for EMR log storage."
  type        = string
  default     = "s3n://aws-logs-123456789012-us-east-1/elasticmapreduce/"
}

# ── Managed Scaling ───────────────────────────────────────────────────────────
variable "enable_managed_scaling" {
  description = "Enable EMR Managed Scaling for automatic node scaling."
  type        = bool
  default     = true
}

variable "scaling_min_capacity" {
  description = "Minimum total capacity units for managed scaling."
  type        = number
  default     = 1
}

variable "scaling_max_capacity" {
  description = "Maximum total capacity units for managed scaling."
  type        = number
  default     = 20
}

variable "scaling_max_on_demand" {
  description = "Maximum on-demand capacity units for managed scaling."
  type        = number
  default     = 20
}

variable "scaling_max_core" {
  description = "Maximum core node capacity units for managed scaling."
  type        = number
  default     = 2
}

# ── Tags ──────────────────────────────────────────────────────────────────────
variable "tags" {
  description = "Tags to apply to the EMR cluster."
  type        = map(string)
  default     = {}
}
