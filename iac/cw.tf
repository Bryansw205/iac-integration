resource "aws_cloudwatch_log_group" "upload_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.upload_lambda.function_name}"
  retention_in_days = 14

  tags = { Name = "cw-upload-logs-${var.entorno}" }
}

resource "aws_cloudwatch_log_group" "crop_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.crop_lambda.function_name}"
  retention_in_days = 14

  tags = { Name = "cw-crop-logs-${var.entorno}" }
}

resource "aws_sns_topic" "dlq_alerts" {
  name = "dlq-messages-alerts-topic-${var.entorno}"
}

resource "aws_cloudwatch_metric_alarm" "dlq_alarm" {
  alarm_name          = "dlq-messages-alarm-${var.entorno}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60 
  statistic           = "Maximum"
  threshold           = 0 
  alarm_description   = "Alarma activada: Hay mensajes atascados en la DLQ de imagenes."
  
  alarm_actions       = [aws_sns_topic.dlq_alerts.arn]

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }
}