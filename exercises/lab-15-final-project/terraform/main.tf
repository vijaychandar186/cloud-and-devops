provider "aws" {
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  s3_use_path_style           = true
  endpoints {
    s3  = "http://localhost:4566"
    sns = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "artifacts" {
  bucket        = "lab15-artifacts"
  force_destroy = true
}

resource "aws_sns_topic" "pipeline_notifications" {
  name = "lab15-pipeline-notifications"
}

output "artifacts_bucket" {
  value = aws_s3_bucket.artifacts.bucket
}

output "notifications_topic_arn" {
  value = aws_sns_topic.pipeline_notifications.arn
}
