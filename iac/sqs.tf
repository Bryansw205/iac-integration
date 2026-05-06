resource "aws_sqs_queue" "dlq" {
  name                      = "image-processor-${var.entorno}-image-dlq"
  message_retention_seconds = 1209600

  tags = { Name = "sqs-dlq-${var.entorno}" }
}

resource "aws_sqs_queue" "main_queue" {
  name                       = "image-processor-${var.entorno}-image-queue"
  visibility_timeout_seconds = 360
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 20
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
  tags = { Name = "sqs-main-${var.entorno}" }
}

resource "aws_sqs_queue_policy" "s3_to_sqs" {
  queue_url = aws_sqs_queue.main_queue.id
  policy    = data.aws_iam_policy_document.s3_to_sqs_policy.json
}

data "aws_iam_policy_document" "s3_to_sqs_policy" {
  statement {
    effect    = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.main_queue.arn]
    
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:s3:::image-processor-${var.entorno}-images-*"]
    }
  }
}