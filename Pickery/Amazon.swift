//
//  AWS.swift
//  Pickery
//
//  Created by Okan Arikan on 6/13/16.
//
//

import Foundation
import AWSDynamoDB
import AWSS3
import ReactiveSwift
import Result
import Photos

/// AWS specialization for the backend
class Amazon : Backend {
    
    /// Helper struct to hold AWS data
    struct Region {
        let regionEnum:     AWSRegionType
        let name:           String
        let regionString:   String
        let coordinate:     CLLocationCoordinate2D
    }
    
    /// Constants
    struct Constants {
        static let kPrefix                      =   "pickery"               ///< The prefix to use for the S3 and DynamoDB
        static let kUseTransferUtility          =   true                    ///< Are we using transfer utility for S3 or not
        static let kDynamoDBReadCapacityUnits   =   25                      ///< The default DynamoDB throughput
        static let kDynamoDBWriteCapacityUnits  =   25                      ///< The default DynamoDB throughput
        static let kRefreshPadding              =   TimeInterval(60)        ///< The padding we apply to the date while fetching changes
        
        // The regions we present to the user and their locations for locating the closest one
        static let kAllRegions : [ Region ]     =   [
            Region(regionEnum:.USEast1,      name:"US East (N. Virginia)",        regionString:"us-east-1",        coordinate:CLLocationCoordinate2D(latitude: 37.478397,  longitude: -76.453077)),
            Region(regionEnum:.USWest1,      name:"US West (N. California)",      regionString:"us-west-1",        coordinate:CLLocationCoordinate2D(latitude: 36.778261,  longitude: -119.417932)),
            Region(regionEnum:.USWest2,      name:"US West (Oregon)",             regionString:"us-west-2",        coordinate:CLLocationCoordinate2D(latitude: 43.804133,  longitude: -120.554201)),
            Region(regionEnum:.EUWest1,      name:"EU (Ireland)",                 regionString:"eu-west-1",        coordinate:CLLocationCoordinate2D(latitude: 53.412910,  longitude: -8.243890)),
            Region(regionEnum:.EUCentral1,   name:"EU (Frankfurt)",               regionString:"eu-central-1",     coordinate:CLLocationCoordinate2D(latitude: 50.110922,  longitude: 8.682127)),
            Region(regionEnum:.APSoutheast1, name:"Asia Pacific (Singapore)",     regionString:"ap-southeast-1",   coordinate:CLLocationCoordinate2D(latitude: 1.352083,   longitude: 103.819836)),
            Region(regionEnum:.APNortheast1, name:"Asia Pacific (Tokyo)",         regionString:"ap-northeast-1",   coordinate:CLLocationCoordinate2D(latitude: 35.689487,  longitude: 139.691706)),
            Region(regionEnum:.APNortheast2, name:"Asia Pacific (Seoul)",         regionString:"ap-northeast-2",   coordinate:CLLocationCoordinate2D(latitude: 37.566535,  longitude: 126.977969)),
            Region(regionEnum:.APSoutheast2, name:"Asia Pacific (Sydney)",        regionString:"ap-southeast-2",   coordinate:CLLocationCoordinate2D(latitude: -33.868820, longitude: 151.209296)),
            Region(regionEnum:.APSouth1,     name:"Asia Pacific (Mumbai)",        regionString:"sa-east-1",        coordinate:CLLocationCoordinate2D(latitude: 19.075984,  longitude: 72.877656)),
            Region(regionEnum:.SAEast1,      name:"South America (Sao Paulo)",    regionString:"sa-east-1",        coordinate:CLLocationCoordinate2D(latitude: -23.550520, longitude: -46.633309)),
            Region(regionEnum:.CNNorth1,     name:"China (Beijing)",              regionString:"cn-north-1",       coordinate:CLLocationCoordinate2D(latitude: 39.904211,  longitude: 116.407395)),
            ]
    }
    
    /// The unique identifier for the account
    var identifier      :   String { return accessKey }

    /// The disposibles we are listenning
    let disposibles     =   ScopedDisposable(CompositeDisposable())
    
    /// AWS: Access ID
    let accessKey       :   String
    
    /// AWS: Secret Key
    let secretKey       :   String
    
    /// The default region to use
    let region          :   AWSRegionType
    
    /// The bucket name to use
    let bucketName      :   String
        
    /// The queue responsible for running tasks
    let taskQueue       =   AmazonTaskQueue()
    
    /// Ctor
    ///
    /// - parameter accessKey : AWS access key
    /// - parameter secretKey : AWS secret key
    /// - parameter defaultRegion : The region to use to create AWS resources in
    private init(accessKey: String, secretKey: String, region: AWSRegionType, S3UUID: UUID) {
        
        // Save the parameters
        self.accessKey          =   accessKey
        self.secretKey          =   secretKey
        self.region             =   region
        self.bucketName         =   Constants.kPrefix + "-" + S3UUID.uuidString.lowercased()
        
        // Listen to the background URL stuff so we can do 
        // backgound uploads using AWS SDK
        disposibles += ApplicationState
            .sharedInstance
            .backgroundURLHandle
            .signal
            .observeValues { (application: UIApplication, identifier: String, completion: @escaping CompletionHandler) in
                
                // Deliver the callback to AWS SDK
                AWSS3TransferUtility.interceptApplication(application, handleEventsForBackgroundURLSession: identifier, completionHandler: completion)
            }
    }
    
    /// Figure out the region for a given region string
    ///
    /// - parameter string: The region string like us-west-2
    /// - returns: The region struct that contains information about this region
    class func region(for string: String) -> Region? {
        return Constants.kAllRegions.filter { $0.name == string }.first
    }
    
    /// Remove all backend stuff
    ///
    /// - returns: A signal producer that will remove the backend
    func removeBackend() -> SignalProducer<(), NSError> {
        
        return  Amazon
                .deleteDynamoDBTable(queue: taskQueue, tableName: AmazonModel.dynamoDBTableName())
                .concat(Amazon.deleteS3(queue: taskQueue, bucketName: bucketName))
    }
    
    /// Create an initializer for given credentials
    ///
    /// The initializer will (try) creating the Pickery bucket and the DynamoDB table
    ///
    /// - parameter accessKey: The user's access key
    /// - parameter secretKey: The user's secret key
    /// - parameter region: The region we want to operate in
    /// - returns: A signal provider that will do the initialization
    static func initialize(accessKey: String, secretKey: String, region: AWSRegionType) -> SignalProducer<Backend,NSError> {
        
        // The queue we will use for the initialization only
        let taskQueue = AmazonTaskQueue()
        
        // Do the initialization
        return SignalProducer<(), NSError> { sink,disposible in
            
            // First, set the credentials
            let credentialsProvider =   AWSStaticCredentialsProvider(accessKey: accessKey, secretKey: secretKey)
            let serviceProvider     =   AWSServiceConfiguration(region: region, credentialsProvider: credentialsProvider)
    
            // Setup the log level
            AWSLogger.default().logLevel = .error
    
            // Set these credentials as the default credentials to use
            AWSServiceManager.default().defaultServiceConfiguration = serviceProvider
    
            // Done with the initialization
            sink.sendCompleted()
        }.then(
            
            // Initialize the S3 bucket
            Amazon.initializeDynamoDBTable(queue: taskQueue, tableName: AmazonModel.dynamoDBTableName())
        
            // Initialize S3 bucket
            .then(Amazon.initializeS3(queue: taskQueue).map {
                return Amazon(accessKey: accessKey, secretKey: secretKey, region: region, S3UUID: $0)
            })
        )
    }
    
    /// Create a presigned URL for a key
    func signedURL(for key: String) -> SignalProducer<URL, NSError> {
        return Amazon.signedURLFor(queue: taskQueue, bucketName: bucketName, key: key)
    }
    
    /// Download a remote key
    ///
    /// When the download is done, the uploaded signal will be triggered with
    /// the downloaded key and it's location on disk
    ///
    /// - parameter key:        The remote object key to fetch
    /// - parameter byteRange:  The byte range to fetch
    func download(key: String, to file: URL) -> SignalProducer<(String, URL),NSError> {
        return Amazon.download(queue: taskQueue, bucketName: bucketName, key: key, to: file)
    }
        
    /// Refresh the local cache
    ///
    /// - parameter since: The last modification date
    /// - returns: A signal source that will emit the set of changed assets
    func changes(since: Date) -> SignalProducer<[(String,Double,String?)],NSError> {
        
        // Capture these
        let queue           =   self.taskQueue
        
        return SignalProducer< [ AmazonModel ], NSError> { sink, disposible in
            
                // Ask for the changes
                Amazon.refresh(queue:               queue,
                               timeStateChanged:    (GlobalConstants.double(from: since) - Constants.kRefreshPadding),
                               startKey:            nil,
                               sink:                sink)
            
            // Extract the meta data from AmazonModel
            }.map { models in
                return models.map { model in
                    (model.signature,model.timeStateChanged.doubleValue,model.metaData)
                }
        }
    }
    
    /// Upload a particular asset
    ///
    /// - parameter file: The resource to upload
    /// - returns: The producer that will execute the task
    func upload(file: PendingUploadResource) -> SignalProducer<UploadResourceReceipt,NSError> {
        
        // Upload the individual resources
        return Amazon.uploadResource(queue:         taskQueue,
                                     bucketName:    bucketName,
                                     fileToUpload:  file)
    }
    
    /// Record an asset in DynamoDB
    ///
    /// - parameter metaData: The asset meta data to record
    /// - parameter resources: The resource receipts to go into this asset
    /// - returns: The producer that will execute the task
    func record(asset metaData: [ String : Any ],
                resources:  [ UploadResourceReceipt ]) -> SignalProducer<UploadAssetReceipt,NSError> {
        
        // Record it
        return Amazon.record(asset: metaData,
                             using: taskQueue,
                             with:  resources)
    }
    
    /// Remove the assets from DynamoDB
    ///
    /// - parameter assets: The asset signatures to remove
    /// - returns: The producer that will execute the task
    func remove(assets: [ String ]) -> SignalProducer<String, NSError> {
        
        // Capture the queue
        let queue = taskQueue
        
        // Produce signatures to delete
        return SignalProducer<String, NSError>(values: assets)
            
                // This is where we delete a single asset
                .flatMap(.merge) { signature in
                    Amazon.recordAssetDeletion(queue: queue, signature: signature)
                }
    }
    
    /// Remove keys from S3
    ///
    /// - parameter resources: The resource signatures to remove
    /// - returns: The producer that will execute the task
    func remove(resources: [ String ]) -> SignalProducer<String, NSError> {
        
        return Amazon.removeKeys(queue: taskQueue, bucketName: bucketName, keys: resources)
    }
    
}
