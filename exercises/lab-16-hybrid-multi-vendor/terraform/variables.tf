variable "project_name" {
  description = "Shared prefix for the hybrid demo resources."
  type        = string
  default     = "lab16-hybrid"
}

variable "aws_region" {
  description = "AWS region used by the LocalStack-backed provider."
  type        = string
  default     = "us-east-1"
}

variable "localstack_endpoint" {
  description = "Base URL for the LocalStack edge endpoint."
  type        = string
  default     = "http://localhost:4566"
}

variable "azure_storage_connection_string" {
  description = "Azurite connection string used by Azure CLI."
  type        = string
  default     = "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;"
  sensitive   = true
}

variable "azurite_blob_endpoint" {
  description = "Blob endpoint used to build friendly output URLs."
  type        = string
  default     = "http://127.0.0.1:10000/devstoreaccount1"
}

variable "azure_storage_api_version" {
  description = "Storage API version forced for Azure CLI so Azurite stays compatible with newer Azure CLI releases."
  type        = string
  default     = "2020-04-08"
}
