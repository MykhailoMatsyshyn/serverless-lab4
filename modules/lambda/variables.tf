variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "source_file" {
  description = "Path to the Python source file"
  type        = string
}

variable "handler" {
  description = "Function handler (filename.function_name)"
  type        = string
  default     = "producer.handler"
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table (optional)"
  type        = string
  default     = ""
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS queue (optional)"
  type        = string
  default     = ""
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket (optional)"
  type        = string
  default     = ""
}
