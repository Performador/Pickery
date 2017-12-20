//
//  AssetView.swift
//  Pickery
//
//  Created by Okan Arikan on 8/23/16.
//
//

import UIKit

/// Displays an asset image view and an overlay
class AssetView : UIView, Snapshottable {
    
    /// The subviews
    let imageView   =   AssetImageView(image: nil, asset: nil)
    let overlayView =   AssetOverlayView()
    
    /// The content we are displaying
    var asset           :   Asset? {
        
        didSet {
            imageView.asset     =   asset
            overlayView.asset   =   asset
        }
    }

    /// Ctor
    convenience init(asset: Asset?) {
        self.init(frame: CGRect.zero)
        
        self.asset = asset
        imageView.asset     =   asset
        overlayView.asset   =   asset
    }
    
    /// Ctor
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Add the subviews
        addSubview(imageView)
        addSubview(overlayView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Snapshot the asset view for transition
    func snapshot() -> UIView {
        return AssetView(asset: asset)
    }
    
    /// Layout the subviews
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Layout the subviews
        imageView.frame     =   bounds
        overlayView.frame   =   bounds
    }    
}
