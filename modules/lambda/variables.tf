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
  type    = string
  default = ""
}

variable "sqs_queue_arn" {
  type    = string
  default = ""
}

variable "s3_bucket_arn" {
  type    = string
  default = ""
}

variable "enable_dynamodb" {
  description = "Enable DynamoDB access policy"
  type        = bool
  default     = false
}

variable "enable_sqs" {
  description = "Enable SQS access policy"
  type        = bool
  default     = false
}

variable "enable_s3" {
  description = "Enable S3 access policy"
  type        = bool
  default     = false
}
