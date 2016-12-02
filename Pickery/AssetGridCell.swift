//
//  AssetCell.swift
//  Pickery
//
//  Created by Okan Arikan on 7/1/16.
//
//

import UIKit
import Photos
import ReactiveSwift
import FontAwesome_swift

/// Regular asset display insude a grid view with an overlay
class AssetGridCell: UICollectionViewCell {
    
    /// Da constants
    struct Constants {
        static let kReuseIdentifier =   "AssetGridCell"
        static let kSize            =   CGFloat(24)
        static let kCheckFont       =   UIFont.fontAwesome(ofSize: kSize)
    }
    
    /// The image view that will display the thumbnail
    let assetView = AssetView(frame: CGRect.zero)
    
    /// Displays the select view over the image
    let selectView = UILabel(frame: CGRect.zero)
    
    /// Whether we are currently editing or not
    private var isEditing : Bool = false
    
    /// Are we selected or not
    override var isSelected : Bool {
        didSet {
            selectView.text     =   isSelected ? FontAwesome.checkCircleO.rawValue : FontAwesome.circleO.rawValue
            selectView.sizeToFit()
            setNeedsLayout()
        }
    }
    
    /// Ctor
    override init(frame: CGRect) {
        super.init(frame: frame)
                
        // Setup the selected
        selectView.font         =   Constants.kCheckFont
        selectView.textColor    =   UIColor.white
        selectView.text         =   isSelected ? FontAwesome.checkCircleO.rawValue : FontAwesome.circleO.rawValue
        selectView.sizeToFit()
        selectView.alpha        =   0
        selectView.addShadow(color: UIColor.black)
        
        // Add it as a subview
        addSubview(assetView)
        addSubview(selectView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Is the collection view in the editing mode?
    func set(editing: Bool, animated: Bool) {
        
        // Animated transition?
        if animated {
            UIView.animate(withDuration: 0.5, animations: {
                self.selectView.alpha               =   editing ? 1 : 0
                self.assetView.overlayView.alpha    =   editing ? 0 : 1
            }, completion: { (Bool) in
                self.isEditing                      =   editing
            })
        } else {
            selectView.alpha                =   editing ? 1 : 0
            assetView.overlayView.alpha     =   editing ? 0 : 1
            isEditing                       =   editing
        }
    }
    
    /// Reset the image view animations
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset the asset
        assetView.asset = nil
    }
    
    /// Do the layout
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Cover the entire view
        assetView.frame     =   self.bounds
        
        // Center the select mark
        selectView.center   =   CGPoint(x: bounds.midX, y: bounds.midY)
    }
}

/// MARK: - AssetCell corformance
extension AssetGridCell : AssetCell {
    
    /// The asset we are displaying
    var asset: Asset? {
        get { return assetView.asset }
        set { assetView.asset = newValue }
    }
    
    /// Get the transition view to use
    var transitionView: UIView { return assetView }
    
}
