resource "aws_security_group" "vpce_sqs_sg" {
  name        = "image-processor-vpce-sqs-sg-${var.entorno}"
  description = "Comunicacion SQS y Lambdas por medio de endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "sg-vpce-sqs-${var.entorno}" }
}

resource "aws_security_group" "upload_lambda_sg" {
  name        = "sg-upload-lambda-${var.entorno}"
  description = "Segurity group para Lambda upload"
  vpc_id      = aws_vpc.main.id
  
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  
  tags = { Name = "sg-upload-lambda-${var.entorno}" }
}

resource "aws_security_group" "crop_lambda_sg" {
  name        = "sg-crop-lambda-${var.entorno}"
  description = "Segurity group para Lambda crop"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = { Name = "sg-crop-lambda-${var.entorno}" }
}