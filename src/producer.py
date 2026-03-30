import json
import boto3
import os

sqs = boto3.client("sqs")
QUEUE_URL = os.environ.get("QUEUE_URL")


def handler(event, context):
    try:
        body = json.loads(event.get("body") or "{}")

        name = body.get("name")
        message = body.get("message")

        if not name or not message:
            return {
                "statusCode": 400,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"error": "Fields 'name' and 'message' are required"}),
            }

        sqs.send_message(
            QueueUrl=QUEUE_URL,
            MessageBody=json.dumps({"name": name, "message": message}),
        )

        return {
            "statusCode": 202,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"status": "queued"}),
        }

    except Exception as e:
        print(f"Producer error: {str(e)}")
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": "Internal Server Error"}),
        }
