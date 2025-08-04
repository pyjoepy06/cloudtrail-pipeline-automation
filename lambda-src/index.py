import json
import gzip
import boto3
import os
from urllib.parse import unquote_plus

# AWS clients
s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
sns = boto3.client('sns')

# Replace with your actual resources
dynamodb_name = os.environ.get("dynamodb_name") #passed via Lambda env variable
table = dynamodb.Table(dynamodb_name)
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")  # passed via Lambda env variable

# Load monitored events from JSON
with open("monitored_events.json", "r") as f:
    monitored_event_names = set(json.load(f)["monitoredEvents"])

def lambda_handler(event, context):
    #Debugging lambda_handler
    #print(event)
    
    for sqs_record in event['Records']:
        message = json.loads(sqs_record['body'])
        s3_event = json.loads(message['Message']) if 'Message' in message else message
        if 'Records' not in s3_event:
            print("No SQS 'Records' found in the event.")
            print(f"Event data: {s3_event}")
            return 
        else:
            for record in s3_event['Records']:
                bucket = record['s3']['bucket']['name']
                key = unquote_plus(record['s3']['object']['key'])

                if key.endswith('.gz'):
                    response = s3.get_object(Bucket=bucket, Key=key)
                    with gzip.GzipFile(fileobj=response['Body']) as f:
                        logs = json.loads(f.read())

                    for log_event in logs.get('Records', []):
                        event_name = log_event.get("eventName")
                        if event_name in monitored_event_names:
                            print(f"[MATCH] Event: {event_name}")
                            save_to_dynamodb(log_event)
                            send_alert(log_event)
                        else:
                            print(f"[SKIP] Event: {event_name}")

def save_to_dynamodb(event):
    #Debugging Function
    #print(f"Saving event to DynamoDB: {event}")
    item = {
        "eventID": event["eventID"],
        "eventTime": event["eventTime"],
        "username": event.get("userIdentity", {}).get("userName", "Unknown"),
        "eventName": event.get("eventName", "Unknown"),
        "sourceIPAddress": event.get("sourceIPAddress", "Unknown"),
        "awsRegion": event.get("awsRegion", "Unknown"),
        "eventType": event.get("eventType", "Unknown")
    }
    print(f"Saving event to DynamoDB: {item}")
    table.put_item(Item=item)

def send_alert(event):
    #Debugging Function
    #print(f"SNS Event data: {event}")
    username = event.get("userIdentity", {}).get("userName", "Unknown")
    ip = event.get("sourceIPAddress", "Unknown")
    time = event.get("eventTime", "")
    event_name = event.get("eventName", "Unknown")

    subject = f"[CloudTrail Alert] {event_name} by {username}"
    message = f"""
    Monitored Event Detected: {event_name}
    User: {username}
    IP Address: {ip}
    Time: {time}
    Region: {event.get('awsRegion', 'Unknown')}
    Event ID: {event.get('eventID')} 
"""

    response = sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject=subject,
        Message=message
    )
    print("SNS Alert Sent:", response['MessageId'])
