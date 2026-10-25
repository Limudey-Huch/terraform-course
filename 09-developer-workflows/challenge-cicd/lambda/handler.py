import json
import os

import boto3

table = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])


def handler(event, context):
    # atomic counter: every call adds 1 to the "hits" attribute of the item id="hits"
    result = table.update_item(
        Key={"id": "hits"},
        UpdateExpression="ADD hits :one",
        ExpressionAttributeValues={":one": 1},
        ReturnValues="UPDATED_NEW",
    )

    return {
        "statusCode": 200,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(
            {
                "message": "hello from " + os.environ.get("APP_VERSION", "unknown"),
                "hits": int(result["Attributes"]["hits"]),
            }
        ),
    }
