# aws-lambda-sqs-experiments

This terraform and python code is the result of experimentation used to learn
more about AWS SQS FIFO queues.

## What this does

- Creates a KMS key to encrypt data in SQS
- Creates a FIFO SQS queue
- Creates a Lambda to produce batches of messages with the same MessageGroupId
- Creates a Lambda to consume messages
- Creates an api gateway with two endpoints:
  - `https://sqs-lambda.{$var.domain}/just-queue-it` (produces 10 messages with a matching MessageGroupId)
  - `https://sqs-lambda.{$var.domain}/show-me-what-you-got` (consumes 10 messages)

## Requirements

- Hosted zone in Route53
- ACM cert

## Variables

- `certificate_arn`: certificate arn to use for the api gateway mapping
- `domain`: domain to use for the api gateway mapping

## Usage
```
terraform plan -var 'domain=bluemage.ca' -var 'certificate_arn=arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012'
terraform apply -var 'domain=bluemage.ca' -var 'certificate_arn=arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012'
```

Note that it will take a few minutes for the domain to be associated with
cloudfront.
