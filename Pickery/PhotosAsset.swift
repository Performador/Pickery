//
//  PhotosAsset.swift
//  Pickery
//
//  Created by Okan Arikan on 8/1/16.
//
//

import Foundation
import Photos
import AVFoundation
import ReactiveSwift

/// Represents a photo image request in flight
///
/// It will cancel the request when deallocated 
class PhotosRequest {
    
    /// The request identifier to cancellation
    let requestId       :   PHImageRequestID
    
    /// Ctor
    init(requestId: PHImageRequestID) {
        self.requestId = requestId
    }
    
    /// Cancel the request
    deinit {
        PhotoLibrary.sharedInstance.cachingImageManager.cancelImageRequest(requestId)
    }
}

/// Represents an asset in the photo library
class PhotosAsset : Asset {

    /// The unique identifier
    var identifier      :   String { return localIdentifier }
    
    /// The pixel resolution
    var pixelSize       :   CGSize { return CGSize(width: CGFloat(phAsset.pixelWidth), height: CGFloat(phAsset.pixelHeight)) }
    
    /// The duration
    var durationSeconds :   TimeInterval { return phAsset.duration }
    
    /// Where?
    var location        :   CLLocation? { return phAsset.location }
    
    /// When
    var dateCreated     :   Date? { return phAsset.creationDate }
    
    /// Return the associated resource types
    var resourceTypes   :   [ ResourceType ] { return PHAssetResource.assetResources(for: phAsset).flatMap { ResourceType(resourceType: $0.type) }  }
    
    /// Is this a live photo?
    var isLivePhoto     :   Bool { return phAsset.mediaSubtypes.contains(.photoLive) }
    
    /// Is this a video?
    var isVideo         :   Bool { return phAsset.mediaType == .video }
    
    /// The photos asset
    let phAsset         :   PHAsset
    
    /// The local identifier in case we need it
    var localIdentifier :   String { return phAsset.localIdentifier }
    
    /// If we have this asset already uploaded, here it is
    var remoteAsset     :   RemoteAsset?
    
    /// Ctor
    init(phAsset: PHAsset) {
        
        // Save the class members
        self.phAsset  =   phAsset
    }
        
    /// Request an image
    func requestImage(for view: AssetImageView) -> AnyObject? {
        assertMainQueue()
        
        // We must be the active asset being displayed
        assert(view.asset?.identifier == identifier)
        
        let desiredPixelSize = view.pixelSize
        let cacheKey         = "\(phAsset.localIdentifier)_\(desiredPixelSize)"
        
        // Already exists in the image cache?
        if let image = ImageCache.sharedInstance.imageForAsset(key: cacheKey) {
            view.image = image
        } else {
            let placeholderKey = phAsset.localIdentifier
            
            // Got a placeholder image?
            if let placeholder = ImageCache.sharedInstance.imageForAsset(key: placeholderKey) {
                view.image = placeholder
            }
            
            // We will have to request this image
            let myIdentifier                =   identifier
            let options                     =   PHImageRequestOptions()
            options.resizeMode              =   .exact
            options.deliveryMode            =   .highQualityFormat
            options.isSynchronous           =   false
            options.isNetworkAccessAllowed  =   true
            
            // Fire off the request
            return PhotosRequest(requestId:
                        PhotoLibrary
                            .sharedInstance
                            .cachingImageManager
                            .requestImage(for:          phAsset,
                                          targetSize:   desiredPixelSize,
                                          contentMode: .default,
                                          options:      options,
                                          resultHandler: { (image: UIImage?, info: [AnyHashable : Any]?) in
                    assertMainQueue()
                    
                    // Were able to get an image?
                    if let image = image {
                        
                        // Add the image to cache
                        ImageCache.sharedInstance.addImageForAsset(key: cacheKey, image: image)
                        
                        // Have existing placeholder already larger than this?
                        if let placeholder = ImageCache.sharedInstance.imageForAsset(key: placeholderKey), placeholder.size.width > image.size.width {
                            // Nothing to do, existing placeholder is already good
                            
                        } else {
                            
                            // No placeholder or it's size is smaller than this, record it in the cache
                            ImageCache.sharedInstance.addImageForAsset(key: placeholderKey, image: image)
                        }
                        
                        // Set the image if this is still relevant
                        if view.asset?.identifier == myIdentifier {
                            view.image = image
                        }
                    }
                })
            )
        }
        
        return nil
    }
    
    /// Request a player item
    ///
    /// see Asset
    func requestPlayerItem(pixelSize: CGSize) -> SignalProducer<AVPlayerItem,NSError> {
        
        // Capture the asset
        let phAsset = self.phAsset
        
        return SignalProducer<AVPlayerItem,NSError> { sink, disposible in
            
            // The request options
            let options                     =   PHVideoRequestOptions()
            options.deliveryMode            =   .highQualityFormat
            options.isNetworkAccessAllowed  =   true
            
            // Let's see if we can create a player item directly
            PhotoLibrary
                .sharedInstance
                .cachingImageManager
                .requestPlayerItem(forVideo:        phAsset,
                                   options:         options,
                                   resultHandler:   { (playerItem: AVPlayerItem?, info: [AnyHashable : Any]?) in
                
                // Success?
                if let playerItem = playerItem {
                    sink.send(value: playerItem)
                    sink.sendCompleted()
                } else {
                    var foundVideo = false
                    
                    // No player found, request the file
                    for resource in PHAssetResource.assetResources(for: phAsset) {
                        if resource.type == .video {
                            let fileURL = FileManager.tmpURL.appendingPathComponent(UUID().uuidString)
                        
                            // Configure the resource access options
                            let options = PHAssetResourceRequestOptions()
                            options.isNetworkAccessAllowed    =   true
                            
                            // Write the data
                            PHAssetResourceManager
                                .default()
                                .writeData(for:                 resource,
                                           toFile:              fileURL,
                                           options:             options,
                                           completionHandler:   { (error: Swift.Error?) in
                                            
                                // Got an error?
                                if let error = error {
                                    sink.send(error: error as NSError)
                                } else {
                                    sink.send(value: AVPlayerItem(asset: AVURLAsset(url: fileURL)))
                                    sink.sendCompleted()
                                }
                            })
                            
                            foundVideo = true
                        }
                    }
                    
                    if foundVideo == false {
                        sink.send(error: PickeryError.internalAssetNotFound as NSError)
                    }
                }
            })
        }
    }
    
    /// Request a live photo
    ///
    /// see Asset
    func requestLivePhoto(pixelSize: CGSize) -> SignalProducer<PHLivePhoto,NSError> {
        
        // Capture asset
        let phAsset = self.phAsset
        
        // Fire off the request in a signal producer
        return SignalProducer<PHLivePhoto,NSError> { sink, disposible in
            let options                     =   PHLivePhotoRequestOptions()
            options.deliveryMode            =   .highQualityFormat
            options.isNetworkAccessAllowed  =   true
            
            PhotoLibrary
                .sharedInstance
                .cachingImageManager
                .requestLivePhoto(for:              phAsset,
                                  targetSize:       pixelSize,
                                  contentMode:      PHImageContentMode.aspectFit,
                                  options:          options,
                                  resultHandler:    { (photo: PHLivePhoto?, info: [AnyHashable : Any]?) in
                                    
                // Success?
                if let photo = photo {
                    sink.send(value: photo)
                }
                
                // Done
                sink.sendCompleted()
            })
        }
    }
}
