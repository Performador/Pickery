//
//  AssetOverlayView.swift
//  Pickery
//
//  Created by Okan Arikan on 8/23/16.
//
//

import UIKit
import FontAwesome_swift
import KDCircularProgress
import ReactiveSwift

/// The overlay view that contains information about an asset
class AssetOverlayView : UIView, Snapshottable {
    
    /// Da constants
    struct Constants {
        static let kInsets          =   UIEdgeInsetsMake(5, 5, 5, 5)
        static let kProgressSize    =   CGFloat(24)
    }

    /// The disposibles we are listenning
    let disposibles     =   ScopedDisposable(CompositeDisposable())
    
    /// The content we are displaying
    var asset           :   Asset? {
        
        didSet {
            
            // Got duration (for a video asset)?
            if let duration = asset?.durationSeconds, duration > 0 {
                durationLabel.text      = Formatters.sharedInstance.stringFromDuration(duration: duration)
                durationLabel.sizeToFit()
                durationLabel.isHidden  = false
            } else {
                durationLabel.isHidden  = true
            }
            
            // Change the state label
            updateIcons()
        }
    }
    
    /// The label we are using to display the asset state
    let stateLabel = UILabel(frame: CGRect.zero)
    
    /// If this is a video, we will show the duration in this
    let durationLabel = UILabel(frame: CGRect.zero)
    
    /// The progress view we display during the upload
    let progressView = KDCircularProgress(frame: CGRect.zero)

    /// Convenience initializer
    convenience init(asset: Asset?) {
        self.init(frame: CGRect.zero)
        
        self.asset = asset
    }
    
    /// Ctor
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Setup the state label
        stateLabel.font                 =   Appearance.Constants.kSmallIconFont
        stateLabel.textColor            =   UIColor.white
        stateLabel.addShadow(color: UIColor.black)
        
        // Setup the duration label
        durationLabel.textColor         =   UIColor.white
        durationLabel.font              =   Appearance.Constants.kSmallSysFont
        durationLabel.addShadow(color: UIColor.black)
        
        // Configure the progress view
        progressView.glowMode           =   .noGlow
        progressView.roundedCorners     =   false
        progressView.set(colors: UIColor.white)
        progressView.progressThickness  =   0.5
        progressView.trackThickness     =   0.5
        progressView.isHidden           =   true
        progressView.frame              =   CGRect(origin: CGPoint.zero, size: CGSize(width: Constants.kProgressSize, height: Constants.kProgressSize))
        
        // Create the view hierarchy
        addSubview(stateLabel)
        addSubview(durationLabel)
        addSubview(progressView)
        
        // Listen to the network for upload state changes to update the overlay
        disposibles += Network
                        .sharedInstance
                        .uploadStateChanged
                        .signal
                        .observe(on: UIScheduler())
                        .observeValues { [ unowned self ] value in
                            
                            // Is this the asset we are responsible for?
                            if let localIdentifier = (self.asset as? PhotosAsset)?.localIdentifier, localIdentifier == value {
                                self.updateIcons()
                            }
                        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Create a snapshot view
    func snapshot() -> UIView {
        return AssetOverlayView(asset: asset)
    }
    
    /// Layout the subviews
    override func layoutSubviews() {
        super.layoutSubviews()
        
        stateLabel.viewBottomRight      =   CGPoint(x: bounds.width - Constants.kInsets.right,
                                                    y: bounds.height - Constants.kInsets.bottom)
        
        durationLabel.viewBottomLeft    =   CGPoint(x: Constants.kInsets.left,
                                                    y: bounds.height - Constants.kInsets.bottom)
        
        progressView.viewTopRight       =   CGPoint(x: bounds.width - Constants.kInsets.right,
                                                    y: Constants.kInsets.top)
    }
    
    /// Update the upload state
    func updateIcons() {
        var icon = ""
        
        // Is this a photos asset?
        if let asset = asset as? PhotosAsset {
            
            // Put a mobile phone icon
            icon += FontAwesome.mobile.rawValue
            
            // Only show progress when uploading
            progressView.isHidden = true
            
            // Do we have this already uploaded?
            if asset.remoteAsset != nil {
                icon += " " + FontAwesome.cloud.rawValue
            } else {
                
                // Let's see what the upload state is for this asset
                switch Network.sharedInstance.state(for: asset.localIdentifier) {
                case .some(.uploading(let uploadedBytes,let totalBytes)):
                    if totalBytes > 0 {
                        progressView.progress   =   Double(uploadedBytes) / Double(totalBytes)
                        progressView.isHidden   =   false
                    }
                    
                    icon += " " + FontAwesome.cloudUpload.rawValue
                case .some(.pending):
                    icon += " " + FontAwesome.hourglass.rawValue
                default:
                    break
                }
            }
            
        // Just a remote asset?
        } else if asset is RemoteAsset {
            icon += FontAwesome.cloud.rawValue
        }
        
        // Update the state label
        stateLabel.text =   icon
        stateLabel.sizeToFit()
        
        // Do a new layout
        setNeedsLayout()
    }
}
