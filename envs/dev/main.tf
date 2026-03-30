provider "aws" {
  region = "eu-central-1"
}

locals {
  prefix = "matsyshyn-mykhailo-11"
}

# S3 bucket для архівів feedback
resource "aws_s3_bucket" "feedback_archive" {
  bucket        = "${local.prefix}-feedback"
  force_destroy = true
}

# Модуль DynamoDB
module "database" {
  source     = "../../modules/dynamodb"
  table_name = "${local.prefix}-feedback-table"
}

# Модуль SQS — основна черга + DLQ
module "queue" {
  source     = "../../modules/sqs"
  queue_name = "${local.prefix}-feedback-queue"
}

# Lambda producer — приймає HTTP запит і кидає в SQS
module "producer" {
  source        = "../../modules/lambda"
  function_name = "${local.prefix}-producer"
  source_file   = "${path.root}/../../src/producer.py"
  handler       = "producer.handler"

  environment_variables = {
    QUEUE_URL = module.queue.queue_url
    TABLE_NAME = module.database.table_name
  }

  enable_sqs         = true
  sqs_queue_arn      = module.queue.queue_arn
  enable_dynamodb    = true
  dynamodb_table_arn = module.database.table_arn
}

# Lambda consumer — читає з SQS і зберігає в DynamoDB + S3
module "consumer" {
  source        = "../../modules/lambda"
  function_name = "${local.prefix}-consumer"
  source_file   = "${path.root}/../../src/consumer.py"
  handler       = "consumer.handler"

  environment_variables = {
    TABLE_NAME  = module.database.table_name
    BUCKET_NAME = aws_s3_bucket.feedback_archive.bucket
  }

  enable_dynamodb    = true
  dynamodb_table_arn = module.database.table_arn

  enable_s3     = true
  s3_bucket_arn = aws_s3_bucket.feedback_archive.arn

  enable_sqs    = true
  sqs_queue_arn = module.queue.queue_arn
}

# Тригер — consumer автоматично запускається коли є повідомлення в черзі
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = module.queue.queue_arn
  function_name    = module.consumer.function_arn
  batch_size       = 1
}

# Модуль API Gateway
module "api" {
  source               = "../../modules/api_gateway"
  api_name             = "${local.prefix}-http-api"
  lambda_invoke_arn    = module.producer.invoke_arn
  lambda_function_name = module.producer.function_name
}

output "api_url" {
  value       = module.api.api_endpoint
  description = "Public URL of the API"
}
