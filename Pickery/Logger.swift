//
//  Logger.swift
//  Pickery
//
//  Created by Okan Arikan on 6/28/16.
//
//

import Foundation
import AWSDynamoDB
import AWSS3

/// Defines the category for the log
struct LogCategory : OptionSet {
    let rawValue: Int
    
    static let amazon           =   LogCategory(rawValue: 1 << 0)
    static let diagnostic       =   LogCategory(rawValue: 1 << 1)
    static let connectivity     =   LogCategory(rawValue: 1 << 2)
    static let ui               =   LogCategory(rawValue: 1 << 3)
    static let imageDownloader  =   LogCategory(rawValue: 1 << 4)
    
    /// The categories that we log to the console
    //static let activeCategories : LogCategory = [ .amazon, .diagnostic, .connectivity, .ui ]
    static let activeCategories : LogCategory = [  ]
}

/// The logging logic
class Logger {
    
    /// The constants
    struct Constants {
        
        /// We post a notification with this name for each error
        static let kErrorNotification = "Error"
    }
    
    /// Debug log
    ///
    /// - parameter category: The debugging category for logging
    /// - parameter message: The log message
    class func debug(category: LogCategory, message: String) {
        
        // Should display?
        if LogCategory.activeCategories.contains(category) {
            print(message)
        }
    }
    
    
    /// Log an NSError
    ///
    /// - parameter error: The error to log
    class func error(error: NSError) {
        
        // Always log an error to console
        print(error.displayString)
        
        // Post errors on the math thread
        dispatchMain{
            NotificationCenter
                .default
                .post(name: NSNotification.Name(rawValue: Constants.kErrorNotification), object: nil, userInfo: [ "error": error.displayString ])
        }
    }
    
    /// Da error
    class func error(error: Error) {
        Logger.error(error: error as NSError)
    }
    
    /// Attempt a throwing block and log the errors if any
    ///
    /// We are expecting the block to succeed normally but we can recover
    /// if it fails
    ///
    /// - parameter block: The throwing block to execute
    class func attempt(block: () throws -> Void ) {
        do {
            try block()
        } catch let error {
            Logger.error(error: error)
        }
    }
}
