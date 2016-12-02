//
//  GlobalConstants.swift
//  Pickery
//
//  Created by Okan Arikan on 6/13/16.
//
//

import UIKit

/// The blobal program constants
class GlobalConstants {
    
    /// This is a debug setting we use to indicate whether the app
    /// should clear every local storage when starting
    static let kCleanStart      =   false
    
    /// The file name we use for thumbnails
    static let kThumbnailName   =   "Thumb"
    
    /// The thumbnail heights we will compute
    static let kMinThumbHeight  =   Int(64)
    
    /// The height of the placeholder image
    static let kPlaceholderHeight  =   Int(24)
        
    /// A test/placeholder
    static let kTestImage       =   UIImage(named: "Test")
        
    /// The current UTC0 timestamp
    class func now() -> Double {
        return double(from: Date())
    }
    
    /// Date - double conversion
    class func double(from date: Date) -> Double {
        return date.timeIntervalSince1970
    }
    
    /// Date - double conversion
    class func date(from double: Double) -> Date {
        return Date(timeIntervalSince1970: double)
    }
}
