locals {
  artifacts_bucket_name   = "${var.project_name}-artifacts"
  notifications_topic     = "${var.project_name}-notifications"
  azure_container_name    = "${var.project_name}-artifacts"
  shared_manifest_name    = "hybrid-manifest.json"
  azure_cli_config_dir    = "${path.module}/../.azure"
  local_manifest_filename = "${path.module}/hybrid-manifest.json"
}

provider "aws" {
  region     = var.aws_region
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  s3_use_path_style           = true

  endpoints {
    s3  = var.localstack_endpoint
    sns = var.localstack_endpoint
    iam = var.localstack_endpoint
    sts = var.localstack_endpoint
  }
}

resource "aws_s3_bucket" "artifacts" {
  bucket        = local.artifacts_bucket_name
  force_destroy = true
}

resource "aws_sns_topic" "notifications" {
  name = local.notifications_topic
}

resource "local_file" "hybrid_manifest" {
  filename = local.local_manifest_filename
  content = jsonencode({
    lab            = "lab-16-hybrid-multi-vendor"
    mode           = "local-hybrid-simulation"
    generated_by   = "terraform"
    aws_vendor     = "localstack"
    azure_vendor   = "azurite"
    aws_region     = var.aws_region
    s3_bucket      = aws_s3_bucket.artifacts.bucket
    sns_topic_arn  = aws_sns_topic.notifications.arn
    azure_container = local.azure_container_name
    azure_blob      = local.shared_manifest_name
  })
}

resource "aws_s3_object" "hybrid_manifest" {
  bucket       = aws_s3_bucket.artifacts.bucket
  key          = local.shared_manifest_name
  source       = local_file.hybrid_manifest.filename
  content_type = "application/json"

  depends_on = [local_file.hybrid_manifest]
}

resource "null_resource" "azurite_blob_seed" {
  triggers = {
    azure_cli_config_dir = local.azure_cli_config_dir
    api_version          = var.azure_storage_api_version
    connection_string    = var.azure_storage_connection_string
    container_name       = local.azure_container_name
    blob_name            = local.shared_manifest_name
    manifest_path        = local_file.hybrid_manifest.filename
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      AZURE_CONFIG_DIR               = local.azure_cli_config_dir
      AZURITE_API_VERSION           = var.azure_storage_api_version
      AZURITE_CONNECTION_STRING     = var.azure_storage_connection_string
    }
    command     = <<-EOT
      set -euo pipefail
      mkdir -p "$AZURE_CONFIG_DIR"
      python3 "${path.module}/../scripts/azurite_storage.py" seed \
        --container "${local.azure_container_name}" \
        --blob "${local.shared_manifest_name}" \
        --file "${local_file.hybrid_manifest.filename}" \
        --content-type "application/json" \
        --api-version "$AZURITE_API_VERSION"
    EOT
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    environment = {
      AZURE_CONFIG_DIR               = self.triggers.azure_cli_config_dir
      AZURITE_API_VERSION           = self.triggers.api_version
      AZURITE_CONNECTION_STRING     = self.triggers.connection_string
    }
    command     = <<-EOT
      set -euo pipefail
      mkdir -p "$AZURE_CONFIG_DIR"
      python3 "${path.module}/../scripts/azurite_storage.py" cleanup \
        --container "${self.triggers.container_name}" \
        --blob "${self.triggers.blob_name}" \
        --api-version "$AZURITE_API_VERSION" || true
    EOT
  }

  depends_on = [aws_s3_object.hybrid_manifest]
}
