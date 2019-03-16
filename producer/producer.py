import boto3
import json
import os
import uuid

def handler(event, context):
    message_group_id = str(uuid.uuid4())[:8]
    queue_arn = os.getenv('SQS_QUEUE_ARN')
    queue_name = queue_arn.split(':')[-1]
    sqs = boto3.resource('sqs')
    queue = sqs.get_queue_by_name(QueueName=queue_name)

    for i in range(10):
        response = queue.send_message(
            MessageBody='this is message number {}'.format(i),
            MessageGroupId=message_group_id,
            MessageDeduplicationId='{}-{}'.format(message_group_id, i)
        )

    return {
        'statusCode': 200,
        'body': json.dumps(
            'Queued 10 messages with message group id {}'.format(
                message_group_id
            )
        )
    }
