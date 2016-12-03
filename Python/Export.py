import botocore
import boto3
import json
import os
import argparse

# The prefix we use for the S3 bucket
PICKERY_PREFIX='pickery'

def makeUniqueFileName(targetDirectory, desiredName):
    '''
    Take a desired file name and create a unique one so we do not overwrite the existing files
    '''
    iteration =  0

    # The desired name we want
    fileName = os.path.join(targetDirectory, desiredName)

    # Keep appending an integer until we have a unique file name
    while os.path.exists(fileName):
        parts = desiredName.split('.')
        iteration += 1
        fileName = os.path.join(targetDirectory, '.'.join(parts[:-1]) + '_' + str(iteration) + '.' + parts[-1])

    return fileName

def exportTo(destination):
    '''
    Export all assets into a directory
    '''

    # Make sure the output directory exists
    if os.path.exists(destination) == False:
        os.makedirs(destination)

    # Grab the clients
    dynamoDB    = boto3.client('dynamodb')
    S3          = boto3.client('s3')

    # This is where we will store the bucket
    assetBucketName = None

    # Find the bucket where we store the assets
    for bucket in S3.list_buckets()['Buckets']:
        bucketName = bucket['Name']
        if bucketName.startswith(PICKERY_PREFIX):
            assetBucketName = bucketName

    # Scan the meta data for the assets
    response    = dynamoDB.scan(TableName=PICKERY_PREFIX)

    # For each asset
    for item in response['Items']:

        # Parse the meta data JSON
        asset = json.loads(item['metaData']['S'])

        # Filter out the Thumbnail resources
        resources = [ i for i in asset['resources'] if i['entryType'] != 'Thumbnail']

        # For each remaining resource associated with this asset
        for resource in resources:

            try:

                # Download it from S3
                S3.download_file(assetBucketName, resource['signature'], os.path.join(destination, makeUniqueFileName(destination, resource['fileName'])))
            except KeyError:
                pass

def listAssets():
    '''
    List everything we have
    '''

    # Grab the clients
    dynamoDB    = boto3.client('dynamodb')
    S3          = boto3.client('s3')


    # Find the bucket where we store the assets
    for bucket in S3.list_buckets()['Buckets']:
        bucketName = bucket['Name']
        if bucketName.startswith(PICKERY_PREFIX):
            print('Found {} bucket'.format(bucketName))

    # Scan the meta data for the assets
    response    = dynamoDB.list_tables()
    for tableName in response['TableNames']:
        if tableName == PICKERY_PREFIX:
            print('Found {} table'.format(tableName))

            # For each asset
            for item in dynamoDB.scan(TableName=PICKERY_PREFIX)['Items']:
                
                try:
                    # Parse the meta data JSON
                    asset = json.loads(item['metaData']['S'])

                    # Dump the info
                    print('- {} Asset, {}x{}'.format(asset['entryType'], asset['pixelWidth'], asset['pixelHeight']))
                except KeyError:
                     print('- Deleted asset')


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Export your assets into a directory.')
    parser.add_argument('--out', type=str,
                        help='where the output images will go')

    args = parser.parse_args()
    
    try:
        exportTo(args.out)
    except botocore.exceptions.NoRegionError:
        print('Please set AWS_DEFAULT_REGION to where your assets are stored')
    except botocore.exceptions.ClientError as e:
        print(e)