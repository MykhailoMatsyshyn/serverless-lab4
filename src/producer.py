import json
import boto3
import os

sqs = boto3.client("sqs")
dynamodb = boto3.resource("dynamodb")

QUEUE_URL = os.environ.get("QUEUE_URL")
TABLE_NAME = os.environ.get("TABLE_NAME")


def handler(event, context):
    try:
        http_method = event.get("requestContext", {}).get("http", {}).get("method", "")
        path = event.get("rawPath", "")

        # GET /feedback/{id}/mood — новий ендпоінт лаб. 5
        if http_method == "GET" and path.endswith("/mood"):
            parts = path.strip("/").split("/")
            # /feedback/{id}/mood → ["feedback", "{id}", "mood"]
            if len(parts) != 3:
                return {
                    "statusCode": 400,
                    "headers": {"Content-Type": "application/json"},
                    "body": json.dumps({"error": "Invalid path"}),
                }
            item_id = parts[1]
            table = dynamodb.Table(TABLE_NAME)
            result = table.get_item(Key={"id": item_id})
            item = result.get("Item")
            if not item:
                return {
                    "statusCode": 404,
                    "headers": {"Content-Type": "application/json"},
                    "body": json.dumps({"error": "Feedback not found"}),
                }
            return {
                "statusCode": 200,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({
                    "id": item_id,
                    "message": item.get("message"),
                    "sentiment": item.get("sentiment"),
                    "sentiment_scores": item.get("sentiment_scores"),
                }),
            }

        elif http_method == "POST":
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

        elif http_method == "GET":
            table = dynamodb.Table(TABLE_NAME)
            response = table.scan()
            items = response.get("Items", [])
            total = len(items)
            last_received = None
            if items:
                sorted_items = sorted(items, key=lambda x: x.get("created_at", ""), reverse=True)
                last_received = sorted_items[0].get("created_at")
            return {
                "statusCode": 200,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({
                    "stats": {"total": total, "last_received": last_received},
                    "items": items,
                }),
            }

        return {
            "statusCode": 405,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": "Method Not Allowed"}),
        }

    except Exception as e:
        print(f"Producer error: {str(e)}")
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": "Internal Server Error"}),
        }