# Create an S3 bucket to store raw data
resource "aws_s3_bucket" "data-bucket" {
  bucket = var.source_bucket_name
  tags = {
    Name        = "data-bucket"
    Environment = "Dev"
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "example.py"
  output_path = "lambda_function_payload.zip"
}

# Define a Lambda function using Terraform with Python 3.8 runtime
resource "aws_lambda_function" "etl_lambda" {
  description      = "ETL Lambda function"
  function_name    = "etl-lambda"
  filename         = "lambda_function_payload.zip"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = "300"
  memory_size      = "256"
  publish          = true
  role             = aws_iam_role.lambda_role.arn
  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.data-bucket.bucket
    }
  }
}


# Configure IAM role with necessary permissions for S3 read and DynamoDB write
resource "aws_iam_role" "lambda_role" {
  name = "lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })

  inline_policy {
    name = "lambda-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject",
          ]
          Resource = [
            "${aws_s3_bucket.data-bucket.arn}/*",
            "${aws_s3_bucket.bucket.arn}/*",
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "dynamodb:PutItem",
            "dynamodb:GetItem",
          ]
          Resource = [
            "${aws_dynamodb_table.target_table.arn}",
          ]
        },
      ]
    })
  }
}

# Define a DynamoDB table
resource "aws_dynamodb_table" "target_table" {
  name         = "target-table"
  hash_key     = "TestTableHashKey"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "TestTableHashKey"
    type = "S"
  }

  replica {
    region_name = "us-east-2"
  }

  replica {
    region_name = "us-west-2"
  }
}

resource "aws_glue_job" "my-glue" {
  name     = "etl-job"
  role_arn = aws_iam_role.glue_role.arn

  command {
    script_location = "s3://${aws_s3_bucket.data-bucket.bucket}/example.py"
  }
}

# Configure IAM role with necessary permissions for Glue
resource "aws_iam_role" "glue_role" {
  name = "glue-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })

  inline_policy {
    name = "glue-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject",
          ]
          Resource = [
            "${aws_s3_bucket.data-bucket.arn}/*",
            "${aws_s3_bucket.bucket.arn}/*",
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "dynamodb:PutItem",
            "dynamodb:GetItem",
          ]
          Resource = [
            "${aws_dynamodb_table.target_table.arn}",
          ]
        },
      ]
    })
  }
}

resource "aws_sns_topic" "user_updates" {
  name            = "user-updates-topic"
  delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF
}

resource "aws_kinesis_stream" "test_stream" {
  name             = "terraform-kinesis-test"
  shard_count      = 1
  retention_period = 48

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  tags = {
    Environment = "test"
  }
}

resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream" {
  name        = "terraform-kinesis-firehose-extended-s3-test-stream"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.bucket.arn

    processing_configuration {
      enabled = "true"

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "${aws_lambda_function.lambda_processor.arn}:$LATEST"
        }
      }
    }
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.destination_bucket_name
}

data "aws_iam_policy_document" "firehose_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "firehose_role" {
  name               = "firehose_test_role"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_iam" {
  name               = "lambda_iam"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "archive_file" "lambda-2" {
  type        = "zip"
  source_file = "example.py"
  output_path = "lambda.zip"
}

resource "aws_lambda_function" "lambda_processor" {
  filename      = "lambda.zip"
  function_name = "firehose_lambda_processor"
  role          = aws_iam_role.lambda_iam.arn
  source_code_hash = data.archive_file.lambda-2.output_base64sha256
  handler       = "exports.handler"
  runtime       = "nodejs16.x"
}