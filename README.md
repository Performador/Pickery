<p align="center" style="width:200px;border-radius:25px;-webkit-border-radius:25px;-moz-border-radius:25px;">
  <img width="200px" src="Designs/icon.png" alt="PickeryIcon" />
</p>

# Pickery: Open source photos client

[![Build Status](https://travis-ci.org/Performador/Pickery.svg)](https://travis-ci.org/Performador/Pickery)
![Swift 3.0.x](https://img.shields.io/badge/language-swift%203-4BC51D.svg?style=flat)
![License](http://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat)

This is an iOS client that works with AWS SDK to store your pictures and videos. It handles de-duping and allows deleting the content already uploaded from your phone.

## Storage: AWS S3

Each asset (video, picture ...) is made up of one or more resources. These resources could be the original image data, additional thumbnails, editing data etc.

The binary blobs for these resources are stored on S3 in a bucket that looks like `pickery.XXXX-XXX-XXX-XXXX-XXX` (the UUID is used to avoid bucket name collisions).

## Meta data: AWS DynamoDB

The meta data associated with the assets is stored on DynamoDB in a table named `pickery`. This table will have the following schema:

| Name | Type | Description |
|------|------|-------------|
| signature | string | The unique identifier of the asset. This is the first signature of all resources associated when sorted |
| metaData | string | This is a JSON string containing the asset meta data |
| timeStateChanged | number | This is the number of seconds passed since Jan 1. 1970 at UTC0 |


## Building

`pod repo update && pod install` and then open `Pickery` workspace.
  
## Exporting

Check out `Python/Export.py` for a script that you can use to download all your assets using boto.

# Future

- More platforms (tvOS, watchOS, Android, Web)
- More backends (Remote file system, Google, Apple)

