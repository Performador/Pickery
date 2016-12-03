# Pickery: Open source photos

[![Build Status](https://travis-ci.org/Performador/Pickery.svg)](https://travis-ci.org/Performador/Pickery)
![Swift 3.0.x](https://img.shields.io/badge/language-swift%203-4BC51D.svg?style=flat)
![License](http://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat)

The idea is to provide a photos experience that is
- Flexible: you are not tied to any big company to guide that experience for you
- Cheap: the hosting for your data should not cost arm and a leg
- Secure: your images and videos are encrypted so nobody else can see them
- Simple: the focus here is the absolute bare bones photos experience

## Storage: AWS S3

We store the binary blobs for resources on S3. The key name is the base 64 encoding of the SHA256 of the resource where `\` is substituded with `_`. Let's call this the signature of the resource.

This substitution is done to allow these resources to be downloaded to the local file system and be represented with the signature as the file name.

Pickery will create a bucket that looks like `pickery.XXXX-XXX-XXX-XXXX-XXX` where the last part is a UUID to avoid bucket name collisions. 

## Meta data: AWS DynamoDB

We store the asset meta data in DynamoDB. Asset meta data is a JSON document that contains meta data associated with the asset:

- Asset dimentions, duration (pixel size, duration in seconds)
- Creation date
- Location taken
- Array of associated resources where for each resource:
  - Pixel size, duration
  - File name
  - Type

Pickery will create a table named `pickery` with the following schema:

| Name | Type | Description |
|------|------|-------------|
| signature | string | The unique identifier of the asset. This is the first signature of all resources associated when sorted |
| metaData | string | This is where we store the JSON desctibed above |
| timeStateChanged | number | This is the number of seconds passed since Jan 1. 1970 at UTC0 |


# Future

- More platforms (Android, Web)
- More backends (Remote file system, Google, Apple)

