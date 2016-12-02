import boto3
import json
import os

# The prefix we use for the S3 bucket
PICTORIA_PREFIX='com.pictoria.assets'

def makeUniqueFileName(targetDirectory, desiredName):
    return os.path.join(targetDirectory, desiredName)

def exportTo(destination, region):
    '''
    Export all assets into a directory
    '''

    # Make sure the output directory exists
    if os.path.exists(destination) == False:
        os.makedirs(destination)

    # Grab the clients
    dynamoDB    = boto3.client('dynamodb',region_name=region)
    S3          = boto3.client('s3',region_name=region)

    # This is where we will store the bucket
    assetBucketName = None

    # Find the bucket where we store the pictoria assets
    for bucket in S3.list_buckets()['Buckets']:
        bucketName = bucket['Name']
        if bucketName.startswith(PICTORIA_PREFIX):
            assetBucketName = bucketName

    # Scan the meta data for the assets
    response    = dynamoDB.scan(TableName=PICTORIA_PREFIX)

    # For each asset
    for item in response['Items']:

        # Parse the meta data JSON
        asset = json.loads(item['metaData']['S'])

        # Filter out the Thumbnail resources
        resources = [ i for i in asset['resources'] if i['type'] != 'Thumbnail']

        # For each remaining resource associated with this asset
        for resource in resources:

            # Download it from S3
            S3.download_file(assetBucketName, resource['signature'], os.path.join(destination, makeUniqueFileName(destination, resource['fileName'])))

def listAssets(region):
    '''
    List everything we have in a region
    '''

    # Grab the clients
    dynamoDB    = boto3.client('dynamodb',region_name=region)
    S3          = boto3.client('s3',region_name=region)


    # Find the bucket where we store the pictoria assets
    for bucket in S3.list_buckets()['Buckets']:
        bucketName = bucket['Name']
        if bucketName.startswith(PICTORIA_PREFIX):
            print('Found {} bucket'.format(bucketName))

    # Scan the meta data for the assets
    response    = dynamoDB.list_tables()
    for tableName in response['TableNames']:
        if tableName == PICTORIA_PREFIX:
            print('Found {} table'.format(tableName))

            # For each asset
            for item in dynamoDB.scan(TableName=PICTORIA_PREFIX)['Items']:
                
                try:
                    # Parse the meta data JSON
                    asset = json.loads(item['metaData']['S'])

                    # Dump the info
                    print('- {} Asset, {}x{}'.format(asset['type'], asset['pixelWidth'], asset['pixelHeight']))
                except KeyError:
                     print('- Deleted asset')


if __name__ == "__main__":
    #exportTo('/tmp/ExportTest', 'us-west-2')
    listAssets('us-west-2')