//
//  Keychain.swift
//  Pickery
//
//  Created by Okan Arikan on 11/11/16.
//
//

import Foundation
import KeychainAccess
import ReactiveSwift

/// Holds the user credentials
class Credentials {
    
    /// Da constants
    struct Constants {
        static let kAccessIdKey     =   "AccessID"
        static let kSecretKeyKey    =   "SecretKey"
        static let kRegionKey       =   "Region"
        static let kKeychainDomain  =   "com.pickery"
    }
    
    /// Singleton stuff
    static let sharedInstance = Credentials()
    
    /// The actual storage
    let keychain = Keychain(service: Constants.kKeychainDomain)
    
    /// Do we have AWS credentials?
    var hasCredentials : Bool {
        return  value(for: Constants.kAccessIdKey) != nil &&
                value(for: Constants.kSecretKeyKey) != nil &&
                value(for: Constants.kRegionKey) != nil
    }
    
    /// AWS Access ID
    var awsAccessId : String? {
        get { return value(for: Constants.kAccessIdKey) ?? env("AWS_ACCESS_KEY_ID") }
        set { set(value: newValue, for: Constants.kAccessIdKey) }
    }
        
    /// AWS Secret Key
    var awsSecretKey : String? {
        get { return value(for: Constants.kSecretKeyKey) ?? env("AWS_SECRET_ACCESS_KEY") }
        set { set(value: newValue, for: Constants.kSecretKeyKey) }
    }
    
    /// AWS Region
    var awsRegion : String? {
        get { return value(for: Constants.kRegionKey) ?? env("AWS_DEFAULT_REGION") }
        set { set(value: newValue, for: Constants.kRegionKey) }
    }
    
    /// Returns a backend initializer if able
    var initializer : SignalProducer<Backend, NSError>? {
        guard let accessId    = awsAccessId,
              let secretKey   = awsSecretKey,
              let regionStr   = awsRegion,
              let region      = Amazon.region(for: regionStr) else {
            return nil
        }
        
        // Set the backend and let's go
        return Amazon.initialize(accessKey: accessId, secretKey: secretKey, region: region.regionEnum)
    }
    
    /// Ctor
    init() {
        
        // Should we clear the credentials
        if GlobalConstants.kCleanStart {
            Logger.attempt {
                try keychain.remove(Constants.kAccessIdKey)
                try keychain.remove(Constants.kSecretKeyKey)
                try keychain.remove(Constants.kRegionKey)
            }
        }
    }
    
    /// Lookup an environment variable
    private func env(_ key: String) -> String? {
        
        // See if we have the variable
        guard let value = getenv(key) else {
            return nil
        }
        
        return String(cString: value)
    }
  
    /// Retrieve value for a key
    private func value(for key: String) -> String? {
        return keychain[key]
    }
    
    /// Set the value for a key
    private func set(value: String?, for key: String) {
        keychain[key] = value
    }
}
