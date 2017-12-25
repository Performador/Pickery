//
//  Network.swift
//  Pickery
//
//  Created by Okan Arikan on 11/28/16.
//
//

import Foundation
import ReactiveSwift
import Result
import Reachability

/// The possible states for a local asset during upload
enum UploadState {
    
    /// Waiting to get uploaded
    case pending

    /// Upload in progress
    case uploading(bytesUploaded: Int64,totalBytes: Int64)
    
    /// The upload has failed with an error
    case failed(error: NSError)
}

/// Keeps track of what's going on on the network
class Network {
    
    static let sharedInstance = Network()
    
    /// Do we have wifi connectivity?
    let gotWifi                 =   MutableProperty<Bool>(false)
    
    /// Do we have network connectivity?
    let gotNetwork              =   MutableProperty<Bool>(false)
    
    /// Local identifier -> Upload state
    var uploadStates            =   [ String : UploadState ]()
    
    /// We emit this for let people know of the changes
    let uploadStateChanged      =   SignalSource<String,NoError>()
    
    /// The number of network requests
    let numRequests             =   MutableProperty<Int>(0)
    
    /// To monitor the network reachability
    let reachability            =   Reachability()
    
    /// Ctor
    init() {
        
        // Reachable
        reachability?.whenReachable = { [ unowned self ] reachability in
            self.gotNetwork.value   =   true
            self.gotWifi.value      =   reachability.connection == .wifi
            
            Logger.debug(category: .connectivity, message: "Network reachable. Wifi: \(reachability.connection == .wifi)")
        }
        
        // Not reachable
        reachability?.whenUnreachable = { [ unowned self ] reachability in
            self.gotNetwork.value   =   false
            self.gotWifi.value      =   false
            
            Logger.debug(category: .connectivity, message: "Network not reachable")
        }
        
        // Start the notification
        Logger.attempt {
            try reachability?.startNotifier()
        }
    }
    
    /// Clear the upload records for everything
    func clear() {
        assertMainQueue()
        
        // Must keep the identifiers for notification
        let currentIdentifiers = uploadStates.keys
        
        // Remove everything
        uploadStates.removeAll()
        
        // Send notification for the assets that we cleared
        for identifier in currentIdentifiers {
            uploadStateChanged.observer.send(value: identifier)
        }
    }
    
    /// Find the state for a local identifier
    ///
    /// - parameter localIdentifier: The asset local identifier to query
    /// - returns: The upload state of the asset if any
    func state(for localIdentifier: String) -> UploadState? {
        assertMainQueue()
        
        return uploadStates[localIdentifier]
    }
    
    /// Set the upload state for an asset
    ///
    /// Thread safe
    ///
    /// - parameter state: The upload state
    /// - parameter localIdentifier: The local identifier for the asset we are setting the state
    func set(state: UploadState, for localIdentifier: String) {
        
        // Always update on main queue
        dispatchMain {
            self.uploadStates[localIdentifier] = state
            self.uploadStateChanged.observer.send(value: localIdentifier)
        }
    }
    
    /// Remove an upload record
    ///
    /// Thread safe
    ///
    /// - parameter localIdentifier: The local identifier for the asset we want to remove
    func remove(localIdentifier: String) {
        
        // Always update on main queue
        dispatchMain {
            self.uploadStates.removeValue(forKey: localIdentifier)
            self.uploadStateChanged.observer.send(value: localIdentifier)
        }
    }
    
    /// Update the current progress
    ///
    /// Thread safe
    func updateProgress(oldBytesUploaded: Int64,
                        oldNumBytes: Int64,
                        newBytesUploaded: Int64,
                        newNumBytes: Int64,
                        for localIdentifier: String) {
        
        // Always update on main queue
        dispatchMain {
            switch self.uploadStates[localIdentifier] {
            case .some(.uploading(let bytesUploaded, let totalBytes)):
                self.uploadStates[localIdentifier] = .uploading(bytesUploaded:  bytesUploaded - oldBytesUploaded + newBytesUploaded,
                                                                totalBytes:     totalBytes - oldNumBytes + newNumBytes)
                self.uploadStateChanged.observer.send(value: localIdentifier)
            default:
                break
            }
        }
    }
    
    /// For network activity tracking
    ///
    /// Thread safe
    func willBeginRequest() {
        dispatchMain {
            self.numRequests.value = self.numRequests.value + 1
        }
    }
    
    /// For network activity tracking
    ///
    /// Thread safe
    func didFinishRequest() {
        dispatchMain {
            self.numRequests.value = self.numRequests.value - 1
        }
    }
}
