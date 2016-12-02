//
//  Settings.swift
//  Pickery
//
//  Created by Okan Arikan on 8/22/16.
//
//

import Foundation
import ReactiveSwift

/// A handy class that keeps user defaults around
class UserDefault<Type> {
    
    /// The key name we use in the NSUserDefaults
    let         keyName         :   String
    
    /// The default value we should use
    let         defaultValue    :   Type
    
    /// Getter and setter for the value
    var         value           :   Type {
        get {
            return valueProperty.value
        }
        
        set {
            UserDefaults.standard.setValue(newValue, forKey: keyName)
            assert(UserDefaults.standard.value(forKey: keyName) != nil)
            
            valueProperty.value = newValue
        }
    }
    
    /// In case we want to listen to the changes
    let         valueProperty   :   MutableProperty<Type>
    
    /// Ctor
    init(keyName: String, defaultValue: Type) {
        self.keyName        =   keyName
        self.defaultValue   =   defaultValue
        self.valueProperty  =   MutableProperty<Type>(UserDefaults.standard.value(forKey: keyName) as? Type ?? defaultValue)
    }
}

/// This singleton keeps track of the global user settings
class Settings {
    
    /// The number of parallel upload and downloads
    static let numParallelDownloads    = UserDefault<Int>(keyName: "NumParallelDownloads",  defaultValue: 7)
    static let numParallelUploads      = UserDefault<Int>(keyName: "NumParallelUploads",    defaultValue: 3)
    static let enableUpload            = UserDefault<Bool>(keyName: "EnableUpload",         defaultValue: true)
    static let cellularUpload          = UserDefault<Bool>(keyName: "CellularUpload",       defaultValue: false)
    
    /// Da singleton
    static let sharedInstance          = Settings()
}
