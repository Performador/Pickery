//
//  Appearance.swift
//  Pickery
//
//  Created by Okan Arikan on 8/12/16.
//
//

import Foundation
import UIKit
import FontAwesome_swift

/// Defines the functionality for defining the app appearance
class Appearance {
    
    /// The constants related to the appearance
    struct Constants {
        
        /// Some predefined font sizes
        static let kMainFontName            =   "Heiti SC"
        static let kXLargeFontSize          =   CGFloat(24)
        static let kLargeFontSize           =   CGFloat(20)
        static let kBaseFontSize            =   CGFloat(18)
        static let kSmallFontSize           =   CGFloat(12)
        
        /// System fonts
        static let kXLargeSysFont           =   UIFont.systemFont(ofSize: kXLargeFontSize)
        static let kLargeSysFont            =   UIFont.systemFont(ofSize: kLargeFontSize)
        static let kBaseSysFont             =   UIFont.systemFont(ofSize: kBaseFontSize)
        static let kSmallSysFont            =   UIFont.systemFont(ofSize: kSmallFontSize)
        
        /// FontAwesome fonts
        static let kXLargeIconFont          =   UIFont.fontAwesome(ofSize: kXLargeFontSize)
        static let kLargeIconFont           =   UIFont.fontAwesome(ofSize: kLargeFontSize)
        static let kBaseIconFont            =   UIFont.fontAwesome(ofSize: kBaseFontSize)
        static let kSmallIconFont           =   UIFont.fontAwesome(ofSize: kSmallFontSize)
        
        /// The nice fonts
        static let kXLargeFont              =   UIFont(name: kMainFontName, size: kXLargeFontSize) ?? kXLargeSysFont
        static let kLargeFont               =   UIFont(name: kMainFontName, size: kLargeFontSize) ?? kLargeSysFont
        static let kBaseFont                =   UIFont(name: kMainFontName, size: kBaseFontSize) ?? kBaseSysFont
        static let kSmallFont               =   UIFont(name: kMainFontName, size: kSmallFontSize) ?? kSmallSysFont
    }
    
    /// Setup the app appearance here
    class func setupAppearance() {     
    }
}
