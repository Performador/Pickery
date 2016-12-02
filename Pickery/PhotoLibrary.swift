//
//  PhotoLibraryAsset.swift
//  Pickery
//
//  Created by Okan Arikan on 6/20/16.
//
//

import Foundation
import Photos
import ReactiveSwift
import MobileCoreServices
import ImageIO
import Result

/// Abstracts the photos library on the device
class PhotoLibrary : NSObject, PHPhotoLibraryChangeObserver {
    
    /// Da constants
    struct Constants {
        
        // The minimum refresh interval
        static let kRefreshInterval     =   TimeInterval(1)
    }
    
    /// The singleton
    static let sharedInstance = PhotoLibrary()
    
    /// The caching image manager for the photo library
    let cachingImageManager = PHCachingImageManager()
    
    /// This is where we keep the photo assets
    let assets = MutableProperty< [ PhotosAsset ]>([])
    
    /// We emit this to request a refresh
    let refreshRequest      =   SignalSource<(),NoError>()
    
    /// The disposibles we are listenning
    let disposibles         =   ScopedDisposable(CompositeDisposable())
        
    /// Ctor
    override init() {
        super.init()
        
        // We are interested in changes
        PHPhotoLibrary.shared().register(self)
        
        // Handle the refresh
        disposibles += refreshRequest
            .signal
            .throttle(Constants.kRefreshInterval, on: QueueScheduler())
            .observeValues { [ unowned self ] value in
                
                // We better be off the main queue
                assert(isMainQueue() == false)
                
                // Let's see if we can read the gallery data
                let results         =   PHAsset.fetchAssets(with: nil)
                var photosAssets    =   [ PhotosAsset ]()
                
                // Create an asset record for each of the local assets
                for assetIndex in 0..<results.count {
                    
                    // Add the asset
                    photosAssets.append(PhotosAsset(phAsset: results[assetIndex]))
                }
                
                // Set the value
                self.assets.value = photosAssets
        }
        
        // We need refresh
        setNeedsRefresh()
    }
    
    /// We want to refresh the library
    /// Thread safe
    func setNeedsRefresh() {
        refreshRequest.observer.send(value: ())
    }
    
    /// Remove the assets from photo library
    ///
    /// - parameter assets: The assets we want gone
    /// - returns: A signal producer for the request
    func deleteAssets(assets : [ PHAsset ]) -> SignalProducer<String,NSError> {
        assertMainQueue()
        
        return SignalProducer<String, NSError> { sink, disposible in
            
            // Delete da assets
            PHPhotoLibrary.shared().performChanges({ 
                PHAssetChangeRequest.deleteAssets(assets as NSArray)
            }, completionHandler: { (done: Bool, error: Swift.Error?) in
                
                // Got an error?
                if let error = error {
                    sink.send(error: error as NSError)
                } else {
                    sink.sendCompleted()
                }
            })
        }
    }
    
    /// Handle changes
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        setNeedsRefresh()
    }
}

