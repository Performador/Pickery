# How assets are stored on Amazon

Pickery uses AWS S3 to store asset data (images, movies, thumbnails etc.) and
AWS DynamoDB to sotr asset meta data (resolution, duration etc.)

## S3: Asset file data

Since S3 buckets are shared resource, Pickery creates a unique bucket in your account.

This unique bucket has the name `com.assets.Pickery.[UUID]` where `UUID` is a unique
identifier. Inside this bucket, all assets are represented as `[SHA256_FileName]` where the first
part is the `SHA256` (except the character `/` is substituded with `-` to make it a valid file name) and the 
second part is the original file name

## DynamoDB: Asset meta data
