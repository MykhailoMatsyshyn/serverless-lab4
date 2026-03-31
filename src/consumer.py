import json
import boto3
import os
import uuid
from datetime import datetime, timezone

dynamodb = boto3.resource("dynamodb")
s3 = boto3.client("s3")
# Клієнт створюється поза handler — економія при warm start (фаза INIT)
comprehend = boto3.client("comprehend", region_name="eu-central-1")

TABLE_NAME = os.environ.get("TABLE_NAME")
BUCKET_NAME = os.environ.get("BUCKET_NAME")

table = dynamodb.Table(TABLE_NAME)


def analyze_sentiment(text):
    """Викликає Comprehend detect_sentiment, повертає (label, scores) або (None, None)"""
    try:
        result = comprehend.detect_sentiment(Text=text, LanguageCode="en")
        return result["Sentiment"], result["SentimentScore"]
    except Exception as e:
        print(f"Comprehend error: {str(e)}")
        return None, None  # graceful degradation


def handler(event, context):
    for record in event.get("Records", []):
        try:
            body = json.loads(record["body"])
            item_id = str(uuid.uuid4())
            timestamp = datetime.now(timezone.utc).isoformat()
            message_text = body.get("message", "")

            # AI-аналіз тональності через Amazon Comprehend
            sentiment_label, sentiment_scores = analyze_sentiment(message_text)

            item = {
                "id": item_id,
                "name": body.get("name", "unknown"),
                "message": message_text,
                "created_at": timestamp,
                # Sentiment зберігається поруч з записом у DynamoDB
                "sentiment": sentiment_label,
                # DynamoDB не приймає float — конвертуємо в str
                "sentiment_scores": {
                    k: str(v) for k, v in sentiment_scores.items()
                } if sentiment_scores else None,
            }

            # Зберігаємо у DynamoDB (пропускаємо None поля)
            table.put_item(Item={k: v for k, v in item.items() if v is not None})

            # Архівуємо у S3
            s3_key = f"feedback/{timestamp[:10]}/{item_id}.json"
            s3.put_object(
                Bucket=BUCKET_NAME,
                Key=s3_key,
                Body=json.dumps(item, default=str),
                ContentType="application/json",
            )
            print(f"Saved item {item_id} sentiment={sentiment_label}")

        except Exception as e:
            print(f"Consumer error on record: {str(e)}")
            raise