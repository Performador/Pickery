//
//  RemoteLibrary.swift
//  Pickery
//
//  Created by Okan Arikan on 9/3/16.
//
//

import Foundation
import Photos
import Result
import ReactiveSwift

/// Abstracts a remote library
class RemoteLibrary {
    
    /// Da constants
    struct Constants {
        
        // The minimum refresh interval
        static let kRefreshInterval     =   TimeInterval(1)
    }
    
    /// The singleton
    static let sharedInstance = RemoteLibrary()
    
    /// The type for the callback
    typealias ImageCompletionBlock = (UIImage) -> Void
    
    /// A single request
    typealias ImageCompletionRequest = (Int, ImageCompletionBlock)
    
    /// We emit this to request a refresh
    let refreshRequest      =   SignalSource<(),NoError>()
    
    /// Da local file cache
    let fileCache           =   FileCache()
    
    /// The disposibles we are listenning
    let disposibles         =   ScopedDisposable(CompositeDisposable())
    
    /// The task queue for the uploads
    let uploadQueue         =   TaskQueue<PHAsset, UploadAssetReceipt>(numSimultaneousTasks: Settings.numParallelUploads)
    
    /// The task queue for the downloads
    let downloadQueue       =   TaskQueue<String, ()>(numSimultaneousTasks: Settings.numParallelDownloads)
    
    /// The pending completion blocks for asset download
    var pendingClients      =   [ String : [ ImageCompletionRequest ] ]()
    
    /// This is for cancellation. We keep track of the request if to asset mapping
    var requestToAsset      =   [ Int : String ]()
    
    /// The current request we are processing
    var currentRequestId    =   Int(0)
    
    /// The backend storage
    let backend             =   MutableProperty<Backend?>(nil)
    
    /// The cache that manages the local persistence
    var cache               :   AssetCache?
    
    /// The current remote assets
    let assets              =   MutableProperty< [ RemoteAsset ]>([])
    
    /// Can we go ahead we uploads?
    var uploadEnabled       :   Bool { return backend.value != nil && Settings.enableUpload.value == true && (Settings.cellularUpload.value == true || Network.sharedInstance.gotWifi.value == true) }
    
    /// Ctor
    init() {
        
        // Set the task execution block for upload
        uploadQueue.executor = { [unowned self] asset in
            
            // Do we have backend?
            if  let backend = self.backend.value,
                let cache   = self.cache {
            
                            // Get the resources to upload for the asset
                return      asset.uploadResources
                    
                            // See if we have uploaded any of the individual files before
                            .flatMap(.merge) { fileToUpload in
                                
                                return SignalProducer<PendingUploadResource, NSError> { sink, disposible in
                                    
                                    // See if we already uploaded this before
                                    if let signature = cache.parent(for: fileToUpload.signature) {
                                        
                                        // Error out
                                        sink.send(error: PickeryError.alreadyUploaded(signature: signature) as NSError)
                                    } else {
                                        
                                        // We can proceed with this file
                                        sink.send(value: fileToUpload)
                                        sink.sendCompleted()
                                    }
                                }
                        
                            // Upload the resources
                            } .flatMap(.merge) { fileToUpload in
                                
                                // Upload the individual resources
                                return backend.upload(file: fileToUpload)
                        
                            // Wait until all uploads are done
                            }.collect()
                    
                            // Record the asset meta data on DynamoDB
                            .flatMap(.merge) { uploadReceipts in
                        
                                // Record it
                                return backend.record(asset: asset.metaData, resources: uploadReceipts)
                                
                            // Monitor the task
                            }.on(
                                
                                // Starting to upload
                                started: {
                                    Network.sharedInstance.set(state: .uploading(bytesUploaded: 0, totalBytes: 0), for: asset.localIdentifier)
                                },
                                
                                // Something went wrong
                                failed: { error in
                                    
                                    // If this is an already uploaded error, it's fine, just update the record
                                    if let signature = error.userInfo["signature"] as? String, error.domain == PickeryError.Constants.kErrorDomain {
                                        cache.recordUpload(for: asset.localIdentifier, signature: signature)
                                        self.setNeedsRefresh()
                                    } else {
                                        Logger.error(error: error)
                                    }
                                },
                                
                                // Done finished uploading it
                                completed: {
                                    self.setNeedsRefresh()
                                },
                                
                                // Done (either succeeded or failed)
                                terminated: {
                                    Network.sharedInstance.remove(localIdentifier: asset.localIdentifier)
                                },
                                
                                // Done with success
                                value: { uploadReceipt in
                                    cache.recordUpload(for: asset.localIdentifier, signature: uploadReceipt.signature)
                                })
                
            } else {
                
                // The backend is not ready yet
                return SignalProducer<UploadAssetReceipt, NSError> { sink, disposible in
                    sink.send(error: PickeryError.backendNotReady as NSError)
                }
            }
        }
        
        // Set the task executor for image download
        downloadQueue.executor = { [unowned self]  signature in
            
            // This is where we want to download the file to
            let fileURL = self.fileCache.urlForKey(key: signature)
            
            // Start downloading
            return self.backend.value?
                        .download(key: signature, to: fileURL)
                        .map { _ in return () }
                        .on(
                            
                            // Done (either succeeded or failed)
                            terminated: {
                    
                                // Deliver the download done
                                dispatchMain {
                                    self.finishDownload(for: signature)
                                }
                        
                            // Done, succeeded
                            }, value: { _ in
                        
                                // The image decode must not be happenning in the main queue
                                assert(!isMainQueue())
                                
                                // The key is downloaded here ... do what is necessary
                                if let image = UIImage(contentsOfFile: fileURL.path) {
                                    
                                    // Deliver the image to waiting views on the main thread
                                    dispatchMain {
                                        self.deliverImage(for: signature, image: image)
                                    }
                                }
                            })
            
                    ?? RemoteLibrary.notReady()
            
            }
        
        // Listen to the changes that would effect the upload
        disposibles += Network.sharedInstance.gotWifi.producer
            .combineLatest(with: Network.sharedInstance.gotNetwork.producer)
            .combineLatest(with: Settings.cellularUpload.valueProperty.producer)
            .combineLatest(with: Settings.enableUpload.valueProperty.producer)
            .observe(on: UIScheduler())
            .on(value: { [ unowned self ] _ in
                
                // Cancel the uploads if necessary
                if self.uploadEnabled == false {
                    self.cancelUploads()
                }
            })
            .start()
        
        // Handle the refresh
        disposibles += refreshRequest
                        .signal
                        .throttle(Constants.kRefreshInterval, on: QueueScheduler())
                        .observeValues { [ unowned self ] value in
                            
                            // We better be off the main queue
                            assert(!isMainQueue())
                            
                            // Do we have a backend?
                            if  let backend = self.backend.value,
                                let cache   = self.cache {
                                
                                // Start a refresh
                                backend
                                    .changes(since: cache.latestUpdate)
                                    .on(failed: { error in
                                        Logger.error(error: error)
                                    }, completed: { 
                                        self.assets.value = cache.assets
                                    }, value: { changes in
                                        cache.update(deltaChanges: changes)
                                    })
                                    .start()
                            }
                        }
    }
    
    /// A helper function for creating a not ready backend
    class func notReady<T>() -> SignalProducer<T,NSError> {
        return SignalProducer<T,NSError> { sink, disposible in
            sink.send(error: PickeryError.backendNotReady as NSError)
        }
    }
    
    /// Return the cached local URL for a signature
    ///
    /// Thread safe
    ///
    /// - parameter signature: The signature we want
    /// - returns: The URL if this signature was cached locally
    func getCachedFileURL(for signature: String) -> URL? {
        let url = fileCache.urlForKey(key: signature)
        
        return url.exists ? url : nil
    }
    
    /// Fetch a URL for a remote item
    ///
    /// - parameter signature: The signature to fetch
    /// - parameter isFileURL: Whether the object must be downloaded to the file cache first
    func url(for signature: String,isFileURL: Bool) -> SignalProducer<URL,NSError> {
        
        // Got backend?
        guard let backend = backend.value else {
            return RemoteLibrary.notReady()
        }
        
        // Do we require a file URL?
        if isFileURL == false {
            return backend.signedURL(for: signature)
        } else {
            
            // Let's see where the cached version is on disk
            let url = fileCache.urlForKey(key: signature)
            
            // Is it already here?
            if url.exists {
                
                // Send it off
                return SignalProducer<URL,NSError> { sink, disposible in
                    sink.send(value: url)
                    sink.sendCompleted()
                }
                
            // OK, we need to download it
            } else {
                return backend.download(key: signature, to: url).map { _ in
                    return url }
            }
            
        }
    }
    
    /// Create a player item for a signature
    ///
    /// - parameter signature: The resource signature we want the player item for
    /// - returns: The player item signal producer
    func playerItem(for signature: String) -> SignalProducer<AVPlayerItem,NSError> {
        
        // Got backend?
        guard let backend = backend.value else {
            return RemoteLibrary.notReady()
        }
        
        // Create a presigned URL and send it off
        return backend
                .signedURL(for: signature)
                .map { url in
                    return AVPlayerItem(asset: AVURLAsset(url: url))
                }
    }

    // Send a refresh request
    func setNeedsRefresh() {
        refreshRequest.observer.send(value: ())
    }
}

/// Backend initialization / deinitialization
extension RemoteLibrary {
    
    /// This is where we install a backend
    ///
    /// - parameter backend: The backend to install
    func install(backend: Backend?) {
        
        // Cancel all existing backend activity
        downloadQueue.cancelAll()
        uploadQueue.cancelAll()
        Network.sharedInstance.clear()
        
        // Got a valid backend?
        if let backend = backend {
            
            // Allocate the new cache
            cache = AssetCache(identifier: backend.identifier)
        } else {
            
            // No more cache
            cache = nil
        }
        
        // Set the backend value
        self.backend.value = backend
        
        // Refresh the local cache
        setNeedsRefresh()
    }
    
    /// This function will 
    func initializeBackend(producer: SignalProducer<Backend,NSError>) {
        
        // Do the initialization in the background
        producer
            .observe(on: UIScheduler())
            .on(started: {
                
                // No backend
                self.install(backend: nil)
                
            }, failed: { error in
                
                // Log da error
                Logger.error(error: error)
            }, value: { backend in
                
                // Set the backend
                self.install(backend: backend)
            })
            .start()
        
        
    }
    
    /// Remove it
    func removeBackend() -> SignalProducer<(),NSError> {
        
        return backend.value?.removeBackend().then(SignalProducer<(),NSError> { sink, disposible in
            
            // Remove the local records
            self.cache?.clear()
            
            // Done here
            sink.sendCompleted()
            
        }) ?? SignalProducer<(),NSError> { sink, disposible in
            sink.sendCompleted()
        }
    }
    
    /// Remove the transient data
    func resetTransientData() {
        
        // Clear the file cache
        fileCache.clear()
        
        // Clear the cache
        cache?.clear()
    }
}

/// Asset upload  / delete functionality
extension RemoteLibrary {
    
    /// Start uploading an asset to the remote storage
    func queueUpload(asset: PHAsset) {
        assertMainQueue()
        
        // The upload must be enabled
        if uploadEnabled && (Network.sharedInstance.state(for: asset.localIdentifier) == nil) {
                
            // Mark the asset as pending
            Network.sharedInstance.set(state: .pending, for: asset.localIdentifier)
            
            // Queue it
            uploadQueue.queue(task: asset)
        }
    }
    
    /// Remove some assets
    func remove(assets: [ RemoteAsset ]) -> SignalProducer<(),NSError> {
        

        
        if let backend = backend.value {
            
            return backend.remove(assets: assets.map { $0.signature })
                .flatMap(.merge) { _ in
                    return backend.remove(resources: assets.flatMap{ $0.resources}.map { $0.signature })
                }.map { _ in
                    return ()
                }.on(completed: {
                    
                    // Refresh the local cache
                    self.setNeedsRefresh()
                })
        } else {
            
            return SignalProducer<(),NSError> { sink, disposible in
                sink.sendCompleted()
            }
        }
    }
        
    /// Cancel all uploads
    func cancelUploads() {
        Logger.debug(category: .connectivity, message: "Cancelling uploads")
        
        // Remove everything pending from the queue
        uploadQueue.cancelAll()
        
        // Nothing is being uploaded
        Network.sharedInstance.clear()
        
    }
}

/// Image download functionality
extension RemoteLibrary {
    
    /// We got an image, deliver it to the vaiting clients
    func deliverImage(for asset: String, image: UIImage) {
        assertMainQueue()
        
        // Deliver the image to the waiting completion blocks
        if let blocks = pendingClients[asset] {
            for block in blocks {
                block.1(image)
            }
        }
    }
    
    /// Done downloading the image
    func finishDownload(for asset: String) {
        assertMainQueue()
        
        // Deliver the image to the waiting completion blocks
        if let blocks = pendingClients[asset] {
            for block in blocks {
                requestToAsset.removeValue(forKey: block.0)
            }
        }
        
        pendingClients.removeValue(forKey: asset)
        assert(pendingClients[asset] == nil)
    }
    
    /// Start downloading an image for
    func downloadImageRequest(asset: String, completion: @escaping ImageCompletionBlock) -> Int {
        assertMainQueue()
        
        let requestId = currentRequestId
        
        currentRequestId += 1
        
        // Already downloading this signature?
        if pendingClients[asset] != nil {
            pendingClients[asset]?.append((requestId, completion))
            
            downloadQueue.check()
        } else {
            assert(pendingClients[asset] == nil)
            pendingClients[asset] = [ (requestId, completion) ]
            
            // Queue the download
            downloadQueue.queue(task: asset)
        }
        
        requestToAsset[requestId] = asset
        return requestId
    }
    
    /// Cancel a particular signature
    func cancelImageRequest(requestId: Int) {
        assertMainQueue()
        
        if let asset = requestToAsset[requestId] {
            if let clients = pendingClients[asset] {
                let filteredClients = clients.filter { $0.0 != requestId }
                
                if filteredClients.count > 0 {
                    pendingClients[asset] = filteredClients
                } else {
                    pendingClients.removeValue(forKey: asset)
                    downloadQueue.cancel(task: asset)
                }
            }
            
            requestToAsset.removeValue(forKey: requestId)
        }
    }
    
}
