variable "lambda_function_name" {
  default = "etl_lambda_function"
}

variable "source_bucket_name" {
  type        = string
  default     = "my-aws-raw-data-bucket"
  description = "The name for the source s3 bucket"
}

variable "destination_bucket_name" {
  type        = string
  default     = "destination-data-bucket"
  description = "The name for the destination s3 bucket"
}