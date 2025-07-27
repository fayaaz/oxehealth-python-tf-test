import boto3
import botocore
import os
import sys
from PIL import Image
import logging

# Handle lambda's special logging
if len(logging.getLogger().handlers) > 0:
    # The Lambda environment pre-configures a handler logging to stderr. If a handler is already configured,
    # `.basicConfig` does not execute. Thus we set the level directly.
    logging.getLogger().setLevel(logging.INFO)
else:
    logging.basicConfig(level=logging.INFO)

def serialize_event_data(json_data):
    """
    Extract data from s3 event
    Args:
        json_data ([type]): Event JSON Data
    """
    bucket = json_data["Records"][0]["s3"]["bucket"]["name"]
    timestamp = json_data["Records"][0]["eventTime"]
    s3_key = json_data["Records"][0]["s3"]["object"]["key"]
    s3_data_size = json_data["Records"][0]["s3"]["object"]["size"]
    ip_address = json_data["Records"][0]["requestParameters"][
        "sourceIPAddress"]
    event_type = json_data["Records"][0]["eventName"]
    owner_id = json_data["Records"][0]["s3"]["bucket"]["ownerIdentity"][
        "principalId"]
    
    return_json_data = {
        "event_timestamp": timestamp,
        "bucket_name": bucket,
        "object_key": s3_key,
        "object_size": s3_data_size,
        "source_ip": ip_address,
        "event_type": event_type,
        "owner_identity": owner_id
    }

    return return_json_data

def handler(event, context):
    """
    Handle the created or update file event and strip EXIF
    data. Upload file to different bucket from original.
    """
    s3_event = serialize_event_data(event)
    s3_file_path = s3_event['object_key']

    logging.info(f'File uploaded: {s3_file_path}')
    filename, file_extension = os.path.splitext(s3_file_path)

    # Check for .jpg and return if not
    if file_extension == '.jpg':
        logging.info('File has .jpg extension - processing...')
    else:
        logging.info('File doesn\'t have .jpg extension - exiting')
        return

    input_bucket = s3_event['bucket_name']
    output_bucket = os.environ['OUTPUT_S3_BUCKET']
    s3_client = boto3.resource('s3')
    # Download file locally
    s3_client.Bucket(input_bucket).download_file(s3_file_path, '/tmp/to_process.jpg')
    # Opening and saving should strip the exif data
    # https://stackoverflow.com/questions/19786301/python-remove-exif-info-from-images/51213844#51213844
    image = Image.open('/tmp/to_process.jpg')
    image.save('/tmp/processed.jpg')
    logging.info('Uploading to output bucket')
    s3_client.Bucket(output_bucket).upload_file('/tmp/processed.jpg', s3_file_path)

