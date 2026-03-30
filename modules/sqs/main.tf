# Dead-Letter Queue — "запасна черга" для повідомлень які не вдалось обробити
resource "aws_sqs_queue" "dlq" {
  name                      = "${var.queue_name}-dlq"
  message_retention_seconds = 1209600 # 14 днів
}

# Основна черга
resource "aws_sqs_queue" "main" {
  name                      = var.queue_name
  message_retention_seconds = 86400 # 1 день

  # Після 3 невдалих спроб — повідомлення іде в DLQ
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}
