output "state_bucket_name" {
  description = "Copy to config.yaml → terraform.state_bucket"
  value       = aws_s3_bucket.tf_state.id
}

output "state_bucket_arn" {
  value = aws_s3_bucket.tf_state.arn
}

output "lock_table_name" {
  description = "Copy to config.yaml → terraform.lock_table"
  value       = aws_dynamodb_table.tf_lock.name
}

output "lock_table_arn" {
  value = aws_dynamodb_table.tf_lock.arn
}

output "next_steps" {
  value = <<-EOT
    ✓ Bootstrap complete.

    Add the following to config/config.yaml:
      terraform:
        state_bucket: ${aws_s3_bucket.tf_state.id}
        lock_table:   ${aws_dynamodb_table.tf_lock.name}
        state_region: ${var.aws_region}

    You can now run the other Terraform modules via the Launchpad UI.
  EOT
}
