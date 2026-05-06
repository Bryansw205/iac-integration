output "api_endpoint_url" {
  description = "LA URL PÚBLICA PARA PROBAR TU APLICACIÓN"
  value       = "${aws_apigatewayv2_api.http_api.api_endpoint}/upload"
}

output "s3_bucket_name" {
  description = "Nombre exacto del bucket de imágenes"
  value       = aws_s3_bucket.images.bucket
}

output "sqs_main_queue_url" {
  description = "URL de la cola principal de SQS"
  value       = aws_sqs_queue.main_queue.id 
}

output "sqs_dlq_queue_url" {
  description = "URL de la cola de mensajes fallidos (DLQ)"
  value       = aws_sqs_queue.dlq.id
}

output "lambda_upload_name" {
  description = "Nombre de la función Lambda de subida"
  value       = aws_lambda_function.upload_lambda.function_name
}

output "lambda_crop_name" {
  description = "Nombre de la función Lambda de procesamiento"
  value       = aws_lambda_function.crop_lambda.function_name
}