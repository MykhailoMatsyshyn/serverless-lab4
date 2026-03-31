# Автоматично пакує .py файл у .zip для деплою в Lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = var.source_file
  output_path = "${path.module}/${var.function_name}.zip"
}

# IAM роль — дозвіл для Lambda запускатись
resource "aws_iam_role" "lambda_exec" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Базова політика — дозволяє Lambda писати логи в CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Політика доступу до DynamoDB (якщо enable_dynamodb = true)
resource "aws_iam_role_policy" "dynamodb_access" {
  count = var.enable_dynamodb ? 1 : 0
  name  = "${var.function_name}-dynamodb-policy"
  role  = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:Scan", "dynamodb:UpdateItem"]
      Resource = var.dynamodb_table_arn
    }]
  })
}

# Політика доступу до SQS (якщо enable_sqs = true)
resource "aws_iam_role_policy" "sqs_access" {
  count = var.enable_sqs ? 1 : 0
  name  = "${var.function_name}-sqs-policy"
  role  = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sqs:SendMessage", "sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
      Resource = var.sqs_queue_arn
    }]
  })
}

# Політика доступу до S3 (якщо enable_s3 = true)
resource "aws_iam_role_policy" "s3_access" {
  count = var.enable_s3 ? 1 : 0
  name  = "${var.function_name}-s3-policy"
  role  = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject", "s3:GetObject"]
      Resource = "${var.s3_bucket_arn}/*"
    }]
  })
}

# Політика доступу до Comprehend (якщо enable_comprehend = true)
resource "aws_iam_role_policy" "comprehend_access" {
  count = var.enable_comprehend ? 1 : 0
  name  = "${var.function_name}-comprehend-policy"
  role  = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["comprehend:DetectSentiment"]
      Resource = "*"
    }]
  })
}

# Сама Lambda функція
resource "aws_lambda_function" "this" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = var.function_name
  role          = aws_iam_role.lambda_exec.arn
  handler       = var.handler
  runtime       = "python3.12"

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = var.environment_variables
  }
}
