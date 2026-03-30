variable "api_name" {
  description = "Name of the HTTP API"
  type        = string
}

variable "lambda_invoke_arn" {
  description = "Invoke ARN of the producer Lambda"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the producer Lambda function"
  type        = string
}
