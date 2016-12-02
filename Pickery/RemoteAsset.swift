//
//  RemoteAsset.swift
//  Pickery
//
//  Created by Okan Arikan on 7/25/16.
//
//

import Foundation
import AVFoundation
import Result
import ReactiveSwift
import CoreLocation
import Photos

/// Allow cancellation of requests
class RemoteRequest {
    
    /// The signature we are requesting
    var requestId   :   Int
    
    /// Ctor
    init(requestId: Int) {
        self.requestId  =   requestId
    }
    
    /// Fire off the cancellation
    deinit {
        RemoteLibrary.sharedInstance.cancelImageRequest(requestId: requestId)
    }
}

/// Looks up the resources for an asset
protocol ResourceProvider {
    
    /// Find all objects associated with a signature
    func resources(for assetSignature: String) -> [ CachedRemoteResource ]
}

/// Represents a remote asset mainly interacts with RemoteLibrary to provide functionality
class RemoteAsset : Asset {
    
    /// Da constants
    struct Constants {
        static let kPlaceHolderPrefix   =   "PlaceHolder_"
        static let kImageResourceTypes : [ String ] =   [ ResourceType.photo.rawValue, ResourceType.thumbnail.rawValue]
    }
    
    /// The unique identifier
    var identifier      :   String { return signature }
    
    /// The pixel size
    var pixelSize       :   CGSize { return CGSize(width: CGFloat(asset.pixelWidth), height: CGFloat(asset.pixelHeight)) }
    
    /// The duration
    var durationSeconds :   TimeInterval { return TimeInterval(asset.durationSeconds) }
    
    /// The location
    var location        :   CLLocation? { return asset.location }
    
    /// The date taken
    var dateCreated     :   Date? { return asset.dateTaken }
    
    /// Return the associated resource types
    var resourceTypes   :   [ ResourceType ] { return resources.flatMap { ResourceType(rawValue: $0.type) } }
    
    /// Is this a live photo
    var isLivePhoto     :   Bool { return resourceTypes.contains(ResourceType.pairedVideo) }
    
    /// Is this a video?
    var isVideo         :   Bool { return resourceTypes.contains(ResourceType.video) }
    
    /// The cached asset meta data
    let asset           :   CachedRemoteAsset
    
    /// The unique signature for the asset
    var signature       :   String { return asset.signature }
    
    /// The associated resources
    var resources       :   [ CachedRemoteResource ] { return provider.resources(for: signature) }
    
    /// The disposibles we are listenning
    let disposibles     =   ScopedDisposable(CompositeDisposable())
    
    /// Where we came from
    let provider        :   ResourceProvider
        
    /// Ctor
    init(remoteAsset: CachedRemoteAsset, provider: ResourceProvider)  {
        
        // Save the asset
        self.asset      =   CachedRemoteAsset(value: remoteAsset)
        
        // Keep the cache around
        self.provider   =   provider
    }
    
    /// Find the best resource to display for a type and size
    ///
    /// - parameter size: The pixel size we want to display this image
    /// - returns: The remote resource we should use (if any)
    func bestImage(for size: CGSize) -> CachedRemoteResource? {
        
        // Find the best resource to display
        var bestResource : CachedRemoteResource?
        
        // Find the best resource which is the one with the smaller resolution
        // greater than size
        var bestPixels = Int(0)
        
        /// The desired pixels we want
        let desiredPixels = Int(size.width * size.height)
        
        // Find the best thumb size
        for resource in resources {
            
            // Is this a resource type we care about?
            if Constants.kImageResourceTypes.contains(resource.type) {
                
                // The number of pixels in the resource
                let pixels = resource.pixelWidth * resource.pixelHeight
                
                // Is this better than the best we have?
                if (bestResource == nil) ||
                    ((pixels > desiredPixels) && (pixels < bestPixels)) ||
                    ((pixels < desiredPixels) && (pixels > bestPixels)) {
                    
                    // Let's keep this
                    bestResource    = resource
                    bestPixels      = pixels
                }
            }
        }
        
        // Unable to find a resource?
        if bestResource == nil {
            Logger.debug(category: .diagnostic, message: "Was unable to find the best resource for \(signature)")
        }
        
        return bestResource
    }
    
    /// Decode an image in the background thread for a view
    ///
    /// - parameter view: The image view that will show the image
    /// - parameter signature: The signature for the image resource (used to cache the decoded image)
    /// - parameter decodeBlock: The code to execute to decode the image
    func decodeImage(for view: AssetImageView,
                     signature: String,
                     with decodeBlock: @escaping () -> UIImage?) {
        let myIdentifier = identifier
        
        // Go back to background queue
        dispatchBackground {
            
            // Can decode the image?
            if let image = decodeBlock() {
                
                // Back to the main queue
                dispatchMain {
                    
                    // Save the image in the cache
                    ImageCache.sharedInstance.addImageForAsset(key: signature, image: image)
                    
                    // Is the view still displaying my identifier?
                    if view.asset?.identifier == myIdentifier &&
                        (view.image?.size.width ?? 0) < image.size.width {
                        view.image  =   image
                    }
                }
            }
        }
    }
    
    /// Request a resource
    ///
    /// see Asset
    func requestImage(for view: AssetImageView) -> AnyObject? {
        let desiredPixelSize = view.pixelSize
        
        // Find the image we want
        guard let resource = bestImage(for: desiredPixelSize) else {
            return nil
        }
        
        // Exact hit in the in memory cache??
        if let image = ImageCache.sharedInstance.imageForAsset(key: resource.signature) {
            assert(image.size != CGSize.zero)
            
            view.image = image
        } else {
            
            // Find the largest thumbnail image we have in memory
            let thumbnail = resources.filter  { return $0.type == ResourceType.thumbnail.rawValue }
                                     .flatMap { return ImageCache.sharedInstance.imageForAsset(key: $0.signature) }
                                     .reduce(UIImage(), { (partial: UIImage, current: UIImage) -> UIImage in
                                        return (current.size.width > partial.size.width) ? current : partial
                                    })
            
            // Set the thumbnail
            view.image = thumbnail
        
            // Do we have the image in the local file cache?
            if let fileCacheURL = RemoteLibrary.sharedInstance.getCachedFileURL(for: resource.signature) {
            
                // Decode the image from the local file cache
                decodeImage(for: view,
                            signature: resource.signature,
                            with: { () -> UIImage? in
                    return UIImage(contentsOfFile: fileCacheURL.path)
                })
            
            // Need to hit the backend
            } else {
                
                // If it does not exist, we need to decode the placeholder
                if thumbnail.size == CGSize.zero {
                    
                    // The memory key for keeping the placeholder image
                    let placeholderKey = "Placeholder_\(asset.signature)"
                    
                    // In memory already?
                    if let placeholder = ImageCache.sharedInstance.imageForAsset(key: placeholderKey) {
                        view.image = placeholder
                        
                    // Need to decode
                    } else if let placeholderData = self.resources.filter({ $0.placeholder != nil }).first?.placeholder {
                        
                        // Decode the placeholder image in background as well
                        decodeImage(for: view, signature: placeholderKey, with: { () -> UIImage? in
                            return UIImage(data: placeholderData)
                        })
                    }
                }
                
                // If the size is insufficient, hit the backend
                if thumbnail.size.width < desiredPixelSize.width {
                    let signature = resource.signature
                    
                    // TODO: Should we also fetch the best thumbnail image for the pixel size?
                    
                    // Create a request
                    return RemoteRequest(requestId: RemoteLibrary
                                                        .sharedInstance
                                                        .downloadImageRequest(asset: signature,
                                                                              completion: { image in
                        assertMainQueue()
                        
                        // Add the image to the image cache for future reference
                        ImageCache.sharedInstance.addImageForAsset(key: signature, image: image)
                        
                        // Set the image for the view
                        view.image = image
                    }))
                }
            }
        }
        
        // No active request
        return nil
    }
    
    /// Request the player item
    ///
    /// see Asset
    func requestPlayerItem(pixelSize: CGSize) -> SignalProducer<AVPlayerItem,NSError> {
        
        // Capture the signature for the video resource
        let videoResourceSignature = resources.filter { $0.type == ResourceType.video.rawValue }.first?.signature
        
        // Got a video?
        if let videoResourceSignature = videoResourceSignature {
        
            // Request it from the backend
            return RemoteLibrary.sharedInstance.playerItem(for: videoResourceSignature)
        } else {
            return SignalProducer<AVPlayerItem,NSError> { sink, disposible in
                sink.send(error: PickeryError.internalAssetNotFound as NSError)
            }
        }
    }
    
    /// Request the live photo
    ///
    /// see Asset
    func requestLivePhoto(pixelSize: CGSize) -> SignalProducer<PHLivePhoto,NSError> {
        
        // The resources that we care about
        let resources = self.resources.filter { $0.type != ResourceType.thumbnail.rawValue }
        
        // Let's see what resources we have
        return SignalProducer<String, NSError>(values: resources.map { return $0.signature })
            
                // Download them to disk
                .flatMap(.merge) { signature in
                    return RemoteLibrary.sharedInstance.url(for: signature, isFileURL: true)
                }
            
                // Wait for completion
                .collect()
            
                // Create a live photo from them
                .flatMap(.merge) { fileURLs in
                    return SignalProducer<PHLivePhoto,NSError> { sink, disposible in
                        PHLivePhoto.request(withResourceFileURLs: fileURLs, placeholderImage: nil, targetSize: pixelSize, contentMode: PHImageContentMode.aspectFit, resultHandler: { (photo: PHLivePhoto?, info: [AnyHashable : Any]) in
                            if let photo = photo {
                                sink.send(value: photo)
                            }
                            sink.sendCompleted()
                        })
                    }
                }
    }
}
