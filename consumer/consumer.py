import boto3
import json
import os

def handler(event, context):
    queue_arn = os.getenv('SQS_QUEUE_ARN')
    queue_name = queue_arn.split(':')[-1]
    sqs = boto3.resource('sqs')
    queue = sqs.get_queue_by_name(QueueName=queue_name)
    message_list = []

    for message in queue.receive_messages(AttributeNames=['MessageGroupId'], MaxNumberOfMessages=10):
        body = message.body
        group = message.attributes['MessageGroupId']
        message_list.append({ 'body': body, 'group': group })
        message.delete()

    return {
        'statusCode': 200,
        'body': json.dumps(message_list)
    }
