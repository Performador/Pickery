//
//  AssetLiveView.swift
//  Pickery
//
//  Created by Okan Arikan on 11/11/16.
//
//

import Foundation
import PhotosUI
import ReactiveSwift

/// An image view that displays an asset live photo view
class AssetLiveView : PHLivePhotoView {
    
    /// The disposibles we are listenning
    let disposibles     =   ScopedDisposable(CompositeDisposable())
        
    /// The content we are displaying
    var asset           :   Asset? {
        
        didSet {
            requestLivePhoto()
        }
    }
    
    /// Ctor
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // The view hierarchy
        // When we get network connectivity, re-request the asset
        disposibles += Network
            .sharedInstance
            .gotNetwork
            .signal
            .observe(on: UIScheduler()).observeValues { [ unowned self ] gotConnection in
                if gotConnection {
                    self.requestLivePhoto()
                }
            }
    }
    
    // Request the live photo
    func requestLivePhoto() {
        
        asset?
            .requestLivePhoto(pixelSize: bounds.size)
            .observe(on: UIScheduler())
            .on(failed: { error in
            },value: { photo in
                self.livePhoto  =   photo
            })
            .start()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Reset the animations
    func reset() {
        asset = nil
    }
}
