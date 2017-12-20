//
//  AssetView.swift
//  Pickery
//
//  Created by Okan Arikan on 7/21/16.
//
//

import UIKit
import AVFoundation
import Photos
import ReactiveSwift
import Result

/// An image view that displays an asset
class AssetImageView : UIImageView, Snapshottable {
    
    struct Constants {
        
        /// FIXME: Fading is not working well so it disabled for now
        static let kFadeDuration    =   TimeInterval(0)
    }
    
    /// The currently active request for this image
    /// When we overwrite this, any existing active request is cancelled
    var activeRequest   :   AnyObject?
    
    /// When the size changes, we request a new version of the image
    var oldSize         =   CGSize.zero
    
    /// The disposibles we are listenning
    let disposibles     =   ScopedDisposable(CompositeDisposable())
    
    /// The content we are displaying
    var asset           :   Asset? {
        
        // Clear the active image and request
        willSet {
            image          =   nil
            activeRequest  =   nil
        }
        
        // Force layout so we can request a new image
        didSet {
            
            // Override the size and force refresh of the image
            oldSize         =   CGSize.zero
            setNeedsLayout()
        }
    }
    
    /// Blend the image changes
    override var image : UIImage? {
        get { return super.image }
        set {
            
            // Are we fading?
            if Constants.kFadeDuration == 0 {
                super.image = newValue
                
            } else {
                
                // If we are not displaying an image, just set the new image
                guard super.image != nil else {
                    super.image = newValue
                    return
                }
                
                // If the new image is none, just set it
                guard newValue != nil else {
                    super.image = nil
                    return
                }
                
                // Just so we don't get caught with our pants down
                layer.removeAllAnimations()
                
                // Fade the change
                UIView.transition(with:         self,
                                  duration:     Constants.kFadeDuration,
                                  options:      UIViewAnimationOptions.transitionCrossDissolve,
                                  animations:   { super.image = newValue }, completion: nil)
            }
        }
    }
    
    /// Ctor
    override init(frame: CGRect) {
        super.init(frame: frame)

        // Need to clip to bounds since the frame might have different aspect ratio (in AssetCollectionView)
        contentMode     = .scaleAspectFill
        clipsToBounds   = true
        
        // When we get network connectivity, re-request the asset
        disposibles += Network
            .sharedInstance
            .gotNetwork
            .signal
            .observe(on: UIScheduler())
            .observeValues { [ unowned self ] gotConnection in
                if gotConnection {
                    self.oldSize = CGSize.zero
                    self.setNeedsLayout()
                }
            }
        
        // When the backend changes, re-request the asset
        disposibles += RemoteLibrary
            .sharedInstance
            .backend
            .signal
            .observe(on: UIScheduler())
            .observeValues { [ unowned self ] _ in
                self.oldSize = CGSize.zero
                self.setNeedsLayout()
            }
    }
    
    /// Convenience initializer
    convenience init(image: UIImage?, asset: Asset?) {
        self.init(frame: CGRect.zero)
        
        self.image = image
        self.asset = asset
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    /// Create a snapshot view
    func snapshot() -> UIView {
        let imageView           =   UIImageView(frame: frame)
        imageView.image         =   image
        imageView.contentMode   =   contentMode
        imageView.clipsToBounds =   clipsToBounds
        return imageView
    }
        
    /// Handle the layout
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Was there a change in size?
        if bounds.size != oldSize {
            
            // Keep track of this size
            oldSize = bounds.size
            
            // Request the image from asset
            activeRequest = asset?.requestImage(for: self)
        }
    }
}
