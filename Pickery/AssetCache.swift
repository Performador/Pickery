//
//  AssetCache.swift
//  Pickery
//
//  Created by Okan Arikan on 11/30/16.
//
//

import Foundation
import ReactiveSwift
import RealmSwift

/// This class maintains a local database copy of the asset meta data
class AssetCache {
    
    /// Where we store the database file
    let url : URL
    
    /// Query the database for all the assets
    var assets : [ RemoteAsset] {
        return (try? myRealm().objects(CachedRemoteAsset.self).map { RemoteAsset(remoteAsset: $0, provider: self) }) ?? []
    }
    
    /// This is where we keep track of the finished uploads
    ///
    /// When we receive an uploaded notification, the remote asset that just got uploaded may not exist in our cache yet
    /// In that case, we put the upload notification in this dict and upload the local identifier of the remote asset when
    /// we fetch it from the server
    var uploadedSignatures = [ String : String ]()
    
    /// Figure out the latest update time
    var latestUpdate : Date {
        
        // Find the last cached asset
        do {
            for asset in try myRealm().objects(CachedRemoteAsset.self).sorted(byProperty: "dateStateChanged", ascending: false) {
                return asset.dateStateChanged
            }
        } catch _ {
        }
        
        return Date(timeIntervalSince1970: 0)
    }
    
    /// Initialize with a unique identifier
    init(identifier: String) {
        
        // Create a file url for holding the realm database
        url = FileManager.cacheURL.appendingPathComponent(identifier + ".realm")
        
        // Clear the local cache before we start?
        if GlobalConstants.kCleanStart {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    /// Helper function that returns the database handle for the current cache
    ///
    /// Thread safe
    internal func myRealm() throws -> Realm {
        return try Realm(fileURL: url)
    }
    
    /// Figure out the parent asset signature for a given resource signature
    ///
    /// Thread safe
    ///
    /// - parameter resourceSignature: Signature of the resource we are querying
    /// - returns: The parent signature if any
    func parent(for resourceSignature: String) -> String? {
        var assetSignature : String? = nil
        
        Logger.attempt {

            // Figure out if we have an existing record for this
            if let remoteRecord = try myRealm().object(ofType: CachedRemoteResource.self, forPrimaryKey: resourceSignature as AnyObject) {
                assetSignature = remoteRecord.parentSignature
            }
        }
        
        return assetSignature

    }
    
    /// Record an upload for a local identifier.
    ///
    /// Thread safe *
    ///
    /// For remote assets that were uploaded from a local photo, we record the local identifier in the database record
    ///
    /// * FIXME: We might be updating the uploadSignatures from a background thread
    func recordUpload(for localIdentifier: String, signature: String) {
        
        Logger.attempt {
            let realm = try myRealm()
            
            // Does the resource exist in the DB?
            if let asset = realm.object(ofType: CachedRemoteAsset.self, forPrimaryKey: signature) {
                try realm.write {
                    asset.localIdentifier = localIdentifier
                }
            } else {
                
                // The resource record is not created yet, keep this around
                uploadedSignatures[signature] = localIdentifier
            }
        }
    }
    
    /// Update the assets given the delta changes
    ///
    /// Thread safe *
    ///
    /// - parameter deltaChanges: The assets that have been uploaded/modified since the last time
    ///
    /// * FIXME: We might be reading the uploadSignatures from a background thread
    func update(deltaChanges: [ (signature: String, timeStateChanged: Double, metaData: String?) ]) {
        
        Logger.attempt {
            let realm = try myRealm()
            
            // For each received item
            for (signature, timeStateChanged, metaData) in deltaChanges {
                
                // Parse the metadata JSON
                if  let metaData    = metaData,
                    let data        = metaData.data(using: String.Encoding.utf8),
                    let meta        = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions()) as? [ String : AnyObject ] {
                    
                    // Parse the main asset
                    let asset = try CachedRemoteAsset(timeStateChanged: timeStateChanged,
                                                      data: meta)
                    
                    // Set the local identifier if we have any
                    asset.localIdentifier = uploadedSignatures[asset.signature]
                    
                    // Remove this signature if any
                    uploadedSignatures.removeValue(forKey: asset.signature)
                    
                    // Parse the addociated resources
                    let resources : [ CachedRemoteResource ]
                    
                    // Can parse the resources in the meta data?
                    if let resourceMeta = meta[ MetaInfoKey.resources.rawValue ] as? [ [String : AnyObject] ] {
                        resources = try resourceMeta
                            .map { return try CachedRemoteResource(parentSignature: asset.signature, data: $0) }
                            .filter { realm.object(ofType: CachedRemoteResource.self, forPrimaryKey: $0.signature as AnyObject) == nil }
                    } else {
                        resources = [ CachedRemoteResource ]()
                    }
                    
                    // Time to write what we have
                    try realm.write {
                        
                        if realm.object(ofType: CachedRemoteAsset.self, forPrimaryKey: asset.signature as AnyObject) == nil {
                            realm.add(asset)
                        }
                        
                        for resource in resources {
                            realm.add(resource)
                        }
                    }
                    
                // If the metadata is nil, it means the asset has been deleted
                } else {
                    
                    // Found the asset?
                    if let assetToDelete = realm.object(ofType: CachedRemoteAsset.self, forPrimaryKey: signature as AnyObject) {
                        
                        // We will delete these associated resources
                        let resourcesToDelete = resources(for: signature)
                    
                        try realm.write {
                            
                            // Delete the main asset meta data
                            realm.delete(assetToDelete)
                            
                            // Delete the resources associated with this asset
                            realm.delete(resourcesToDelete)
                        }
                    }
                }
            }
        }
    }
    
    /// Clear everything
    func clear() {
        
        Logger.attempt {
            let realm = try Realm(fileURL: url)
            
            try realm.write {
                realm.deleteAll()
            }
        }
    }
}

extension AssetCache : ResourceProvider {
    
    /// Find all resources associated with an asset
    ///
    /// - parameter assetSignature: The signature of the parent asset
    /// - returns: The resource records in the database
    func resources(for assetSignature: String) -> [ CachedRemoteResource ] {
        return (try? myRealm()
            .objects(CachedRemoteResource.self)
            .filter(NSPredicate(format: "parentSignature = %@" , assetSignature))
            .flatMap { return $0  }) ?? []
    }
}
