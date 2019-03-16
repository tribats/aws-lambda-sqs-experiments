provider "aws" {
  version = "~> 2.2"
  region  = "us-east-1"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

module "queue" {
  source = "./modules/sqs"

  name_prefix = "lambda-sqs-example-queue-"
  env         = "sandbox"
  service     = "lambda-sqs-example"
  fifo_queue  = true

  additional_tags = {
    Random = "value"
  }
}

module "api_gateway" {
  source = "./modules/api_gateway"

  domain              = "${var.domain}"
  subdomain           = "lambda-sqs-example"
  certificate_arn     = "${var.certificate_arn}"
  lambda_arn          = "${aws_lambda_function.producer.arn}"
  consumer_lambda_arn = "${aws_lambda_function.consumer.arn}"
}

data "archive_file" "producer-lambda" {
  source_dir  = "${path.module}/../../producer"
  output_path = "${path.module}/../../build/producer.zip"
  type        = "zip"
}

data "archive_file" "consumer-lambda" {
  source_dir  = "${path.module}/../../consumer"
  output_path = "${path.module}/../../build/consumer.zip"
  type        = "zip"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "lambda-sqs-example-iam-for-lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "producer" {
  function_name    = "lambda-sqs-example-producer"
  filename         = "${path.module}/../../build/producer.zip"
  source_code_hash = "${data.archive_file.producer-lambda.output_base64sha256}"
  handler          = "producer.handler"
  runtime          = "python3.6"
  role             = "${aws_iam_role.iam_for_lambda.arn}"

  environment {
    variables {
      SQS_QUEUE_ARN = "${module.queue.arn}"
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda-producer" {
  name              = "/aws/lambda/${aws_lambda_function.producer.function_name}"
  retention_in_days = 14
}

resource "aws_lambda_function" "consumer" {
  function_name    = "lambda-sqs-example-consumer"
  filename         = "${path.module}/../../build/consumer.zip"
  source_code_hash = "${data.archive_file.consumer-lambda.output_base64sha256}"
  handler          = "consumer.handler"
  runtime          = "python3.6"
  role             = "${aws_iam_role.iam_for_lambda.arn}"

  environment {
    variables {
      SQS_QUEUE_ARN = "${module.queue.arn}"
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda-consumer" {
  name              = "/aws/lambda/${aws_lambda_function.consumer.function_name}"
  retention_in_days = 14
}

resource "aws_iam_policy" "lambda" {
  name        = "lambda-sqs-example-lambda"
  path        = "/"
  description = "IAM policy for lambda-sqs-example lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:/aws/lambda/*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "sqs:SendMessage",
        "sqs:SendMessageBatch",
        "sqs:GetQueueUrl",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage"
      ],
      "Effect": "Allow",
      "Resource": "${module.queue.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:GenerateDataKey",
        "kms:Decrypt"
      ],
      "Resource": "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/${module.queue.key_id}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "${aws_iam_policy.lambda.arn}"
}
