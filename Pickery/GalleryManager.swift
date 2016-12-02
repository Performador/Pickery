//
//  GalleryManager.swift
//  Pickery
//
//  Created by Okan Arikan on 9/3/16.
//
//

import Foundation
import Result
import ReactiveSwift

/// Manages the data we show in the galley
class GalleryManager {
    
    /// Da constants
    struct Constants {
        static let kMinDataSourceRefreshRate    =   Double(2)
    }
    
    static let sharedInstance = GalleryManager()
    
    /// The disposibles we are listenning
    let disposibles         =   ScopedDisposable(CompositeDisposable())
    
    /// The latest and current gallery data
    let galleryData         =   MutableProperty<GalleryData>(GalleryData(remoteAssets: RemoteLibrary.sharedInstance.assets.value,
                                                                         photosAssets: PhotoLibrary.sharedInstance.assets.value))
    /// Do the thing
    init() {
        
        // Observe changes in the photo library (photos and remote)
        disposibles += PhotoLibrary.sharedInstance.assets.producer
                        .combineLatest(with: RemoteLibrary.sharedInstance.assets.producer)
                        .throttle(Constants.kMinDataSourceRefreshRate, on: QueueScheduler())
                        .map { (photosAssets, remoteAssets) in
                            assert(isMainQueue() == false)
                            return GalleryData(remoteAssets: remoteAssets,
                                               photosAssets: photosAssets)
                        }
                        .on(value: { galleryData in
                            self.galleryData.value = galleryData
                        })
                        .start()
        
        
        // Listen to the changes in networking and gallery data so we can re-jiggle the upload
        disposibles += Network.sharedInstance.gotNetwork.producer
                        .combineLatest(with: Network.sharedInstance.gotWifi.producer)
                        .combineLatest(with: galleryData.producer)
                        .combineLatest(with: Settings.cellularUpload.valueProperty.producer)
                        .combineLatest(with: Settings.enableUpload.valueProperty.producer)
                        .observe(on: UIScheduler())
                        .on(value: { [ unowned self ] _ in
                            self.uploadLocalAssets()
                        })
                        .start()
    }
    
    /// Upload the local assets that are seen as un-uploaded in the latest gallery data
    func uploadLocalAssets() {
        assertMainQueue()
        
        // Upload the pending assets
        for asset in galleryData.value.unUploaded {
            
            // Queue the asset
            RemoteLibrary.sharedInstance.queueUpload(asset: asset.phAsset)
        }
    }
}
