output "queue_url" {
  description = "SQS queue URL"
  value       = aws_sqs_queue.this.url
}

output "queue_arn" {
  description = "SQS queue ARN"
  value       = aws_sqs_queue.this.arn
}

output "queue_name" {
  description = "SQS queue name"
  value       = aws_sqs_queue.this.name
}

output "dlq_url" {
  description = "DLQ URL (empty string if not created)"
  value       = var.create_dlq ? aws_sqs_queue.dlq[0].url : ""
}

output "dlq_arn" {
  description = "DLQ ARN (empty string if not created)"
  value       = var.create_dlq ? aws_sqs_queue.dlq[0].arn : ""
}
