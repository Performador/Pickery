//
//  Backend.swift
//  Pickery
//
//  Created by Okan Arikan on 6/13/16.
//
//

import Foundation
import ReactiveSwift
import Result

/// The abstraction for the backend
protocol Backend {
    
    /// The unique identifier for the backend
    var identifier : String { get }
    
    /// Removes the entire backend
    func removeBackend() -> SignalProducer<(), NSError>
            
    /// Get the changes to the assets since a date
    func changes(since: Date) -> SignalProducer<[(String,Double,String?)],NSError>
            
    /// Return the signed URL for a key
    func signedURL(for key: String) -> SignalProducer<URL, NSError>
    
    /// Download a particular key to a file
    func download(key: String,to file: URL) -> SignalProducer<(String,URL),NSError>
        
    /// Upload a particular asset
    func upload(file: PendingUploadResource) -> SignalProducer<UploadResourceReceipt,NSError>
    
    /// Record an asset
    func record(asset metaData: [ String : Any ], resources: [ UploadResourceReceipt ]) -> SignalProducer<UploadAssetReceipt,NSError>
    
    /// Remove the assets
    func remove(assets: [ String ]) -> SignalProducer<String, NSError>
    
    /// Remove the resources
    func remove(resources: [ String ]) -> SignalProducer<String, NSError>
}
