resource "aws_emr_cluster" "this" {
  name          = var.name
  release_label = var.release_label
  applications  = var.applications

  service_role                      = var.service_role
  log_uri                           = var.log_uri
  security_configuration            = var.security_configuration
  ebs_root_volume_size              = var.ebs_root_volume_size
  scale_down_behavior               = var.scale_down_behavior
  step_concurrency_level            = var.step_concurrency_level
  termination_protection            = var.termination_protection
  keep_job_flow_alive_when_no_steps = true
  unhealthy_node_replacement        = true

  ec2_attributes {
    key_name         = var.ec2_key_name
    subnet_id        = var.subnet_id
    instance_profile = var.instance_profile
  }

  master_instance_group {
    instance_type = var.master_instance_type

    ebs_config {
      size                 = var.master_ebs_size
      type                 = "gp3"
      volumes_per_instance = 1
    }
  }

  core_instance_group {
    instance_type  = var.core_instance_type
    instance_count = var.core_instance_count

    ebs_config {
      size                 = var.core_ebs_size
      type                 = "gp3"
      volumes_per_instance = 1
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      core_instance_group[0].instance_count,
      core_instance_group[0].ebs_config,
      master_instance_group[0].ebs_config,
      os_release_label,
    ]
  }
}

resource "aws_emr_managed_scaling_policy" "this" {
  count      = var.enable_managed_scaling ? 1 : 0
  cluster_id = aws_emr_cluster.this.id

  compute_limits {
    unit_type                       = "Instances"
    minimum_capacity_units          = var.scaling_min_capacity
    maximum_capacity_units          = var.scaling_max_capacity
    maximum_ondemand_capacity_units = var.scaling_max_on_demand
    maximum_core_capacity_units     = var.scaling_max_core
  }

  lifecycle {
    ignore_changes = all
  }
}
