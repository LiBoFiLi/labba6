provider "aws" {
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3 = "http://localhost:4510"
  }
}

resource "aws_s3_bucket" "s3_start" {
  bucket = "s3-start"
  acl    = "private"
  # Указываем локальный эндпоинт для S3
  force_destroy    = true  # Опционально, для разрешения удаления непустых бакетов
}

resource "aws_s3_bucket" "s3_finish" {
  bucket = "s3-finish"
  acl    = "private"
  # Указываем локальный эндпоинт для S3
  force_destroy    = true  # Опционально, для разрешения удаления непустых бакетов
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda/lambda.zip"
}

resource "aws_lambda_function" "copy_lambda" {
  filename      = "${data.archive_file.lambda_zip.output_path}"
  function_name = "copyLambda"
  role          = "arn:aws:iam::123456789012:role/lambda_role"
  handler       = "index.handler"
  runtime       = "nodejs14.x"
  source_code_hash = filebase64sha256("${data.archive_file.lambda_zip.output_path}")

  environment {
    variables = {
      SOURCE_BUCKET      = aws_s3_bucket.s3_start.bucket
      DESTINATION_BUCKET = aws_s3_bucket.s3_finish.bucket
    }
  }
}

resource "aws_s3_bucket_notification" "lambda_trigger" {
  bucket = aws_s3_bucket.s3_start.bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.copy_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }
}






