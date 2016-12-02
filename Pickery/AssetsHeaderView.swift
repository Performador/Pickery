//
//  AssetsHeaderView.swift
//  Pickery
//
//  Created by Okan Arikan on 7/1/16.
//
//

import UIKit

/// The header view in the collection view
class AssetsHeaderView: UICollectionReusableView {
    
    /// Constants
    struct Constants {
        static let kReuseIdentifier =   "AssetsHeaderView"
        static let kFontSize        =   CGFloat(14)
        static let kFont            =   UIFont.systemFont(ofSize: Constants.kFontSize)
        static let kTextColor       =   UIColor.black
    }
    
    /// The view that will display the text
    let textView    =   UILabel(frame: CGRect.zero)
    
    /// The day we are displaying
    var day         :   Date? {
        didSet {
            guard let day = day else {
                return
            }
            
            textView.text = Formatters.sharedInstance.dateHeaderFormatter.string(from: day)
        }
    }
    
    /// Ctor
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Setup the view hierarchy
        textView.font           =   Constants.kFont
        textView.textColor      =   Constants.kTextColor
        textView.textAlignment  =   .right
        addSubview(textView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Full size label view
    override func layoutSubviews() {
        textView.frame = self.bounds
    }
}
