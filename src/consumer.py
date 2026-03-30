import json
import boto3
import os
import uuid
from datetime import datetime, timezone

dynamodb = boto3.resource("dynamodb")
s3 = boto3.client("s3")

TABLE_NAME = os.environ.get("TABLE_NAME")
BUCKET_NAME = os.environ.get("BUCKET_NAME")

table = dynamodb.Table(TABLE_NAME)


def handler(event, context):
    for record in event.get("Records", []):
        try:
            body = json.loads(record["body"])

            item_id = str(uuid.uuid4())
            timestamp = datetime.now(timezone.utc).isoformat()

            item = {
                "id": item_id,
                "name": body.get("name", "unknown"),
                "message": body.get("message", ""),
                "created_at": timestamp,
            }

            # Зберігаємо у DynamoDB
            table.put_item(Item=item)

            # Архівуємо у S3
            s3_key = f"feedback/{timestamp[:10]}/{item_id}.json"
            s3.put_object(
                Bucket=BUCKET_NAME,
                Key=s3_key,
                Body=json.dumps(item),
                ContentType="application/json",
            )

            print(f"Saved item {item_id} to DynamoDB and S3 at {s3_key}")

        except Exception as e:
            print(f"Consumer error on record: {str(e)}")
            raise
