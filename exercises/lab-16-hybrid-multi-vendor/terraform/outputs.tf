output "localstack_s3_bucket" {
  value       = aws_s3_bucket.artifacts.bucket
  description = "S3 bucket created in LocalStack."
}

output "localstack_sns_topic_arn" {
  value       = aws_sns_topic.notifications.arn
  description = "SNS topic ARN created in LocalStack."
}

output "localstack_manifest_object" {
  value       = "s3://${aws_s3_bucket.artifacts.bucket}/${aws_s3_object.hybrid_manifest.key}"
  description = "Location of the shared manifest in LocalStack S3."
}

output "azurite_container_name" {
  value       = local.azure_container_name
  description = "Blob container created in Azurite."
}

output "azurite_blob_url" {
  value       = "${var.azurite_blob_endpoint}/${local.azure_container_name}/${local.shared_manifest_name}"
  description = "HTTP URL for the manifest blob stored in Azurite."
}
