//
//  Formattera.swift
//  Pickery
//
//  Created by Okan Arikan on 7/25/16.
//
//

import Foundation

/// Various formatters
class Formatters {
    
    /// Singleton stuff
    static let sharedInstance = Formatters()
    
    /// The formatter we use for the collection view headers
    let dateHeaderFormatter = DateFormatter()
    
    /// The formatter we use in the asset meta data
    let ISOFormatter = DateFormatter()
    
    /// The formatter we use to format bytes
    let bytesFormatter = ByteCountFormatter()
    
    /// Ctor
    init() {
        
        // Format the date formatter
        dateHeaderFormatter.dateStyle = DateFormatter.Style.long
        
        // Create the ISO format
        ISOFormatter.locale     = Locale(identifier: "en_US_POSIX")
        ISOFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    }
    
    /// Return a duration string from seconds
    ///
    /// - parameter duration: The duration to convert
    /// - returns: The string that represents that duration
    func stringFromDuration(duration: TimeInterval) -> String {
        let intSeconds  =   Int(duration)
        let seconds     =   intSeconds % 60
        let minutes     =   (intSeconds / 60) % 60
        let hours       =   intSeconds / 3600
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
