# UPLOAD LAMBDA

resource "aws_lambda_function" "upload_lambda" {
  function_name    = "upload-lambda-${var.entorno}"
  role             = aws_iam_role.upload_lambda_role.arn
  
  filename         = data.archive_file.upload_zip.output_path
  source_code_hash = data.archive_file.upload_zip.output_base64sha256

  runtime = "nodejs20.x"
  handler = "index.handler"
  memory_size = 256
  timeout     = 30

  environment {
    variables = {
      S3_BUCKET     = aws_s3_bucket.images.bucket
      UPLOAD_PREFIX = "uploads/"
    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.upload_lambda_sg.id]
  }

  depends_on = [aws_iam_role_policy_attachment.upload_vpc_access]
}

data "archive_file" "upload_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/upload-lambda"
  output_path = "${path.module}/upload-lambda.zip"
}

# CROP LAMBDA

resource "aws_lambda_function" "crop_lambda" {
  function_name    = "crop-lambda-${var.entorno}"
  role             = aws_iam_role.crop_lambda_role.arn
  
  filename         = data.archive_file.crop_zip.output_path
  source_code_hash = data.archive_file.crop_zip.output_base64sha256

  runtime = "nodejs20.x"
  handler = "index.handler"
  memory_size = 512
  timeout     = 60

  environment {
    variables = {
      S3_BUCKET        = aws_s3_bucket.images.bucket
      PROCESSED_PREFIX = "processed/"
    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    # Referenciamos el SG que ahora vive en sg.tf
    security_group_ids = [aws_security_group.crop_lambda_sg.id]
  }

  depends_on = [aws_iam_role_policy_attachment.crop_vpc_access]
}

data "archive_file" "crop_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../src/crop-lambda"
  output_path = "${path.module}/crop-lambda.zip"
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.main_queue.arn
  function_name    = aws_lambda_function.crop_lambda.arn
  
  batch_size                         = 5   
  function_response_types            = ["ReportBatchItemFailures"]
  maximum_batching_window_in_seconds = 0
}