//
//  AmazonS3.swift
//  Pickery
//
//  Created by Okan Arikan on 7/22/16.
//
//

import Foundation
import AWSS3
import ReactiveSwift
import Result

/// S3 specific stuff from Amazon
extension Amazon {
    
    /// List the keys inside a bucket
    ///
    /// - parameter queue: The queue to execute on
    /// - parameter bucketName: The name of the bucket to list
    /// - parameter marker: The start key for pagination
    /// - parameter sink: The sink to send the results to
    internal class func listBucket(queue:        AmazonTaskQueue,
                                   bucketName:   String,
                                   marker:       String?,
                                   sink:         Observer<[String],NSError>) {
        
        // Create the request
        let request : AWSS3ListObjectsRequest = AWSS3ListObjectsRequest()
        request.bucket  =   bucketName
        request.marker  =   marker
        
        // List the objects in this bucket
        queue.run(taskGenerator: { () -> AWSTask<AWSS3ListObjectsOutput> in
                    return AWSS3.default().listObjects(request)
                },description: "Listing bucket contents") { task in
            
            // Error?
            if let error = task.error {
                sink.send(error: error as NSError)
            } else {
                
                // List objects
                if let objects  = task.result,
                    let contents = objects.contents {
                    
                    sink.send(value: contents.flatMap { return $0.key })
                    
                    // Do we have more results?
                    if objects.isTruncated?.boolValue ?? false {
                        Amazon.listBucket(queue:        queue,
                                          bucketName:   bucketName,
                                          marker:       objects.nextMarker,
                                          sink:         sink)
                    } else {
                        sink.sendCompleted()
                    }
                } else {
                    sink.sendCompleted()
                }
            }
        }
    }
    
    
    /// List the keys inside a bucket
    ///
    /// - parameter queue: The queue to execute on
    /// - parameter bucketName: The name of the bucket to list
    /// - returns: The producer that will execute the task
    internal class func listBucket(queue:        AmazonTaskQueue,
                                   bucketName:   String) -> SignalProducer<[String],NSError> {
        
        return SignalProducer<[String],NSError> { sink, disposible in
            
            // List the bucket in a paginated fashion
            Amazon.listBucket(queue: queue, bucketName: bucketName, marker: nil, sink: sink)
        }
    }
    
    /// Delete a bucket
    ///
    /// The bucket must be emoty
    ///
    /// - parameter queue: The queue to execute on
    /// - parameter bucketName: The name of the bucket to delete
    /// - returns: The producer that will execute the task
    internal class func deleteBucket(queue:        AmazonTaskQueue,
                                     bucketName:   String) -> SignalProducer<(),NSError> {
        return SignalProducer<(),NSError> { sink, disposible in
            let request : AWSS3DeleteBucketRequest    =   AWSS3DeleteBucketRequest()
            request.bucket  =   bucketName
            
            // List the objects in this bucket
            queue.run(taskGenerator: {
                return AWSS3.default().deleteBucket(request)
            }, description: "Deleting bucket") { task in
                
                // Error?
                if let error = task.error {
                    sink.send(error: error as NSError)
                } else {
                    sink.sendCompleted()
                }
            }
        }
    }
    
    /// Remove an S3 bucket
    ///
    /// The difference here is that it will clear the bucket first
    ///
    /// - parameter queue:      The task queue to execute the requests
    /// - parameter bucketName: The name of the bucket to remove
    /// - returns: The producer that will execute the task
    internal class func deleteS3(queue:        AmazonTaskQueue,
                                 bucketName:   String) -> SignalProducer<(),NSError> {
        
        return Amazon
                .listBucket(queue: queue, bucketName: bucketName)
                .flatMap(.merge) { return Amazon.removeKeys(queue: queue, bucketName: bucketName, keys: $0) }
                .then(Amazon.deleteBucket(queue: queue, bucketName: bucketName))
    }
    
    /// Remove bunch of keys from S3
    ///
    /// - parameter queue:      The task queue to execute the requests
    /// - parameter bucketName: The name of the bucket to remove
    /// - parameter keys:       The keys to remove
    /// - returns: The producer that will execute the task
    internal class func removeKeys(queue:        AmazonTaskQueue,
                                   bucketName:   String,
                                   keys:         [ String ]) -> SignalProducer<String, NSError> {
        
        return SignalProducer<String, NSError> { sink, disposible in
            Logger.debug(category: .amazon, message: "Removing keys: \(keys)")
            
            let deleteRequest : AWSS3DeleteObjectsRequest = AWSS3DeleteObjectsRequest()
            
            deleteRequest.bucket    =   bucketName
            deleteRequest.remove    =   AWSS3Remove()
            deleteRequest.remove?.objects   = keys.map({ (key: String) -> AWSS3ObjectIdentifier in
                let identifier : AWSS3ObjectIdentifier = AWSS3ObjectIdentifier()
                identifier.key = key
                return identifier
            })
            
            // Execute
            queue.run(taskGenerator: {
                return AWSS3.default().deleteObjects(deleteRequest)
            }, description: "Deleting objects") { task in
                if let error = task.error {
                    sink.send(error: error as NSError)
                } else {
                    Logger.debug(category: .amazon, message: "Done removing keys: \(keys)")
                    
                    for key in keys {
                        sink.send(value: key)
                    }
                    
                    sink.sendCompleted()
                }
            }
        }
    }
    
    /// Initialize the S3
    ///
    /// This will check for the existing pickery buckets and create one if not already exists
    ///
    /// - parameter queue: The task queue to execute the requests
    /// - returns: The producer that will execute the task
    internal class func initializeS3(queue: AmazonTaskQueue) -> SignalProducer<UUID,NSError> {
        
        return SignalProducer<UUID,NSError> { sink, disposible in
            
            let listRequest : AWSRequest = AWSRequest()
            
            queue.run(taskGenerator: {
                return AWSS3.default().listBuckets(listRequest)
            }, description: "Listing your buckets") { task in
                
                // Did we fail?
                if let error = task.error {
                    sink.send(error: error as NSError)
                } else {
                    var id : UUID?
                    
                    // Let's see if we have output
                    if let output = task.result,
                       let buckets = output.buckets {
                        
                        for bucket in buckets {
                            if let bucketName = bucket.name, bucketName.hasPrefix(Amazon.Constants.kPrefix) {
                                id = UUID(uuidString: bucketName.replacingOccurrences(of: Amazon.Constants.kPrefix + "-", with: ""))
                            }
                        }
                    }
                    
                    // Found it?
                    if let id = id {
                        sink.send(value: id)
                        sink.sendCompleted()
                    } else {
                        let id          =   UUID()
                        let config : AWSS3CreateBucketConfiguration     =   AWSS3CreateBucketConfiguration()
                        config.locationConstraint   =   .usWest2
                        
                        let request : AWSS3CreateBucketRequest    =   AWSS3CreateBucketRequest()
                        request.bucket  =   Amazon.Constants.kPrefix + "-" + id.uuidString.lowercased()
                        request.acl     =   .private
                        request.createBucketConfiguration   =   config
                        
                        queue.run(taskGenerator: {
                            return AWSS3.default().createBucket(request)
                        }, description: "Creating new bucket") { task in
                            
                            // Did we fail?
                            if let error = task.error as NSError?, error.code != AWSS3ErrorType.bucketAlreadyOwnedByYou.rawValue {
                                sink.send(error: error as NSError)
                            } else {
                                sink.send(value: id)
                                sink.sendCompleted()
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Upload a resource file to S3 and record it on the DynamoDB
    ///
    /// - parameter queue:      The task queue to execute the requests
    /// - parameter fileToUpload: The pending resource file waiting to upload
    /// - parameter bucketName: The bucket to save to
    /// - returns: The producer that will execute the task
    internal class func uploadResource(queue:            AmazonTaskQueue,
                                       bucketName:       String,
                                       fileToUpload:     PendingUploadResource) -> SignalProducer<UploadResourceReceipt, NSError> {
        
        // Create the signal producer
        return SignalProducer<UploadResourceReceipt, NSError> { sink, disposible in
            assert(fileToUpload.localFileURL.exists)
            
            // If this is a placeholder image, we can create a receipt without uploading
            if let height = fileToUpload.info[MetaInfoKey.pixelHeight.rawValue] as? Int, height == GlobalConstants.kPlaceholderHeight {
                var info = fileToUpload.info
                
                // Load the resource and pack it into the meta data
                do {
                    
                    // Put a base 64 encoded placeholder image into the receipt
                    info[MetaInfoKey.placeholder.rawValue] = try Data(contentsOf: fileToUpload.localFileURL).base64EncodedString()
                    
                    // Done here. No need to upload the placeholder image
                    sink.send(value: UploadResourceReceipt(signature: fileToUpload.signature, data: info))
                    sink.sendCompleted()
                } catch let error {
                    sink.send(error: error as NSError)
                }
            } else {
                
                // Are we using the transfer utility?
                if Constants.kUseTransferUtility {
                    let expression = AWSS3TransferUtilityUploadExpression()

                    // For updating the progress
                    var oldBytesUploaded    = Int64(0)
                    var oldNumBytes         = Int64(0)
                    
                    // Form the expression
                    expression.contentMD5       =   fileToUpload.MD5
                    expression.setValue("private", forRequestParameter: "x-amz-acl")
                    expression.setValue("AES256", forRequestParameter: "x-amz-server-side-encryption")
                    expression.progressBlock    =   { task, progress in
                        
                        // Update the progress
                        Network.sharedInstance.updateProgress(oldBytesUploaded: oldBytesUploaded,
                                                              oldNumBytes:      oldNumBytes,
                                                              newBytesUploaded: progress.completedUnitCount,
                                                              newNumBytes:      progress.totalUnitCount,
                                                              for:              fileToUpload.localIdentifier)
                        
                        oldBytesUploaded    =   progress.completedUnitCount
                        oldNumBytes         =   progress.totalUnitCount
                    }
                    
                    Logger.debug(category: .amazon, message: "Uploading \(fileToUpload.signature)")
                    
                    // Fire it off
                    queue.run(taskGenerator: {
                        return AWSS3TransferUtility
                                .default()
                                .uploadFile(fileToUpload.localFileURL,
                                            bucket:             bucketName,
                                            key:                fileToUpload.signature,
                                            contentType:        fileToUpload.info[MetaInfoKey.mimeType.rawValue] as? String ?? MimeType.unknown.rawValue,
                                            expression:         expression,
                                            completionHandler:  { task, error in
                                                
                                                // The file must still exist after uploading
                                                assert(fileToUpload.localFileURL.exists)
                                                
                                                // Error?
                                                if let error = error {
                                                    sink.send(error: error as NSError)
                                                } else {
                                                    Logger.debug(category: .amazon, message: "Done uploading \(fileToUpload.signature)")
                                                    
                                                    sink.send(value: UploadResourceReceipt(signature: fileToUpload.signature, data: fileToUpload.info))
                                                    sink.sendCompleted()
                                                }
                                })
                    },description: "Uploading resource") { task in
                        
                        // Error?
                        if let error = task.error {
                            sink.send(error: error as NSError)
                        }
                    }
                } else {
                    guard let numBytes = fileToUpload.info[MetaInfoKey.numBytes.rawValue] as? Int else {
                        sink.send(error: PickeryError.internalFoundEmptyFile as NSError)
                        return
                    }
                    
                    // For updating the progress
                    var oldBytesUploaded    = Int64(0)
                    var oldNumBytes         = Int64(0)
                    
                    let request : AWSS3PutObjectRequest =   AWSS3PutObjectRequest()
                    request.acl                     =   .private
                    request.bucket                  =   bucketName
                    request.key                     =   fileToUpload.signature
                    request.body                    =   fileToUpload.localFileURL
                    request.contentLength           =   numBytes as NSNumber
                    request.contentType             =   fileToUpload.info[MetaInfoKey.mimeType.rawValue] as? String
                    request.serverSideEncryption    =   AWSS3ServerSideEncryption.AES256
                    request.contentMD5              =   fileToUpload.MD5
                    request.uploadProgress          =   { bytesSent, totalBytesSent, totalBytesExpectedToSend in
                        
                        // Update the progress
                        Network.sharedInstance.updateProgress(oldBytesUploaded: oldBytesUploaded,
                                                              oldNumBytes: oldNumBytes,
                                                              newBytesUploaded: bytesSent,
                                                              newNumBytes: totalBytesSent,
                                                              for: fileToUpload.localIdentifier)
                        
                        oldBytesUploaded    =   bytesSent
                        oldNumBytes         =   totalBytesSent
                    }
                    
                    // Send it to S3
                    queue.run(taskGenerator: {
                        return AWSS3.default().putObject(request)
                    }, description: "Uploading resource (\(numBytes) bytes)") { task in
                        
                        // Error?
                        if let error = task.error {
                            sink.send(error: error as NSError)
                        } else {
                            sink.send(value: UploadResourceReceipt(signature: fileToUpload.signature, data: fileToUpload.info))
                            sink.sendCompleted()
                        }
                    }
                }
            }
        }
    }
    
    /// Create a pre-signed URL for a key
    ///
    /// You should be able to download this key through this URL without authentication
    ///
    /// - parameter queue:      The task queue to execute the requests
    /// - parameter bucketName: The bucket to save to
    /// - parameter key: The key we want to access
    /// - returns: The producer that will execute the task
    internal class func signedURLFor(queue:            AmazonTaskQueue,
                                     bucketName:       String,
                                     key:              String) -> SignalProducer<URL, NSError> {
        
        return SignalProducer<URL, NSError> { sink, disposible in
            let request         =   AWSS3GetPreSignedURLRequest()
            request.bucket      =   bucketName
            request.key         =   key
            request.httpMethod  =   AWSHTTPMethod.GET
            request.expires     =   Date(timeIntervalSinceNow: 3600)
            
            // Get the presigned URL
            queue.run(taskGenerator: {
                return AWSS3PreSignedURLBuilder.default().getPreSignedURL(request)
            }, description: "Presigning") { task in
                
                // Got error?
                if let error = task.error {
                    sink.send(error: error as NSError)
                } else {
                    
                    if let url = task.result {
                        sink.send(value: url as URL)
                        sink.sendCompleted()
                    } else {
                        sink.send(error: PickeryError.internalAssetNotFound as NSError)
                    }
                }
            }
        }
    }

    /// Download a remote key
    ///
    /// When the download is done, the uploaded signal will be triggered with
    /// the downloaded key and it's location on disk
    ///
    /// - parameter queue:      The task queue to execute the requests
    /// - parameter bucketName: The bucket to save to
    /// - parameter key: The remote object key to fetch
    /// - returns: The producer that will execute the task
    internal class func download(queue:            AmazonTaskQueue,
                                 bucketName:       String,
                                 key:              String,to file: URL) -> SignalProducer<(String, URL),NSError> {
        
        // Return the signal producer
        return SignalProducer<(String, URL),NSError> { sink, disposible in
            
            if Constants.kUseTransferUtility {
                
                Logger.debug(category: .amazon, message: "S3 download start for \(key) using transfer utility")
                
                queue.run(taskGenerator: {
                    return AWSS3TransferUtility
                        .default()
                        .download(to: file,
                            bucket: bucketName,
                            key: key,
                            expression: nil,
                            completionHandler: { (task: AWSS3TransferUtilityDownloadTask, url: URL?, data: Data?, error: Swift.Error?) in
                                // Error?
                                if let error = error {
                                    sink.send(error: error as NSError)
                                } else {
                                    Logger.debug(category: .amazon, message: "S3 download finished for \(key) using transfer utility")
                                    sink.send(value: (key, file))
                                    sink.sendCompleted()
                                }
                        })}, description: "Download key") { task in
                        
                        // Error?
                        if let error = task.error {
                            sink.send(error: error as NSError)
                        }
                }
            } else {
                
                // Form the download request
                let request : AWSS3TransferManagerDownloadRequest                = AWSS3TransferManagerDownloadRequest()
                request.key                 = key
                request.bucket              = bucketName
                request.downloadingFileURL  = file
                
                Logger.debug(category: .amazon, message: "S3 download start for \(key)")
                
                // Start teh transfer
                queue.run(taskGenerator: {
                    return AWSS3TransferManager.default().download(request)
                }, description: "Downloading object") { task in
                    
                    // Got error?
                    if let error = task.error {
                        sink.send(error: error as NSError)
                    } else {
                        Logger.debug(category: .amazon, message: "S3 download finished for \(key)")
                        sink.send(value: (key, file))
                        sink.sendCompleted()
                    }
                }
            }
        }
    }
}
